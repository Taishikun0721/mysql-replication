## Dirty Readとは
他のトランザクションが値をUPDATE文で更新した場合、commitする前にすでに別トランザクションから値を読み出せてしまう。

ただしMySQLの設定でトランザクションレベルがどのようになっているかで、物理ロックのレベルも変化するので
その設定によってDirty Readを防ぐことができるかどうかが決まる。

実際にこの現象が発生するのは、トランザクション分離レベルが `READ-UNCOMMITED`の場合のみとなる

[トランザクション分離レベル確認方法](https://marock.tokyo/2021/07/13/mysql-%E3%83%88%E3%83%A9%E3%83%B3%E3%82%B6%E3%82%AF%E3%82%B7%E3%83%A7%E3%83%B3%E5%88%86%E9%9B%A2%E3%83%AC%E3%83%99%E3%83%AB%E3%82%92%E7%A2%BA%E8%AA%8D%E3%81%99%E3%82%8B%E6%96%B9%E6%B3%95/)

``` sql
mysql> SELECT @@GLOBAL.tx_isolation, @@tx_isolation;
+-----------------------+-----------------+
| @@GLOBAL.tx_isolation | @@tx_isolation  |
+-----------------------+-----------------+
| REPEATABLE-READ       | REPEATABLE-READ |
+-----------------------+-----------------+
1 row in set, 2 warnings (0.00 sec)
```

デフォルトでは`REPETABLE-READ`の設定になっている


## `REPETABLE-READ`の場合

セッションA
``` sql
mysql> select * from users;
+----+--------+
| id | name   |
+----+--------+
|  1 | tanaka |
|  2 | sato   |
+----+--------+
2 rows in set (0.00 sec)
```


セッションB
``` sql
mysql> select * from users;
+----+--------+
| id | name   |
+----+--------+
|  1 | tanaka |
|  2 | sato   |
+----+--------+
2 rows in set (0.00 sec)
```

セッションA
``` sql
mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> update users set name = "tanaka2" where id = 1;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> select * from users;
+----+---------+
| id | name    |
+----+---------+
|  1 | tanaka2 |
|  2 | sato    |
+----+---------+
```

セッションB
``` sql
mysql> select * from users;
+----+--------+
| id | name   |
+----+--------+
|  1 | tanaka |
|  2 | sato   |
+----+--------+
2 rows in set (0.00 sec)
```

そもそもcommitする前に他のセッションから更新された値を取得することは、`REPETABLE READ`ではできない
これは、UPDATE文をトランザクション内で発行した場合に、排他ロックがかかるので、select文での共有ロックはとることができないから整合性は保たれる。


## `READ UNCOMMITTED`の場合

セッションA
``` sql
mysql> SET SESSION  TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT @@GLOBAL.tx_isolation, @@tx_isolation;
+-----------------------+------------------+
| @@GLOBAL.tx_isolation | @@tx_isolation   |
+-----------------------+------------------+
| REPEATABLE-READ       | READ-UNCOMMITTED |
+-----------------------+------------------+
1 row in set, 2 warnings (0.00 sec)

mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from users where id = 1;
+----+---------+
| id | name    |
+----+---------+
|  1 | tanaka2 |
+----+---------+
1 row in set (0.00 sec)

mysql> update users set name = "tanaka" where id = 1;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> select * from users where id = 1;
+----+--------+
| id | name   |
+----+--------+
|  1 | tanaka |
+----+--------+
1 row in set (0.00 sec)
```

↑commitはまだしていない

``` sql
mysql> SET SESSION  TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT @@GLOBAL.tx_isolation, @@tx_isolation;
+-----------------------+------------------+
| @@GLOBAL.tx_isolation | @@tx_isolation   |
+-----------------------+------------------+
| REPEATABLE-READ       | READ-UNCOMMITTED |
+-----------------------+------------------+
1 row in set, 2 warnings (0.00 sec)

mysql> select * from users where id = 1;
+----+---------+
| id | name    |
+----+---------+
|  1 | tanaka2 |
+----+---------+
1 row in set (0.00 sec)

mysql> select * from users where id = 1;
+----+---------+
| id | name    |
+----+---------+
|  1 | tanaka2 |
+----+---------+
1 row in set (0.00 sec)

mysql> select * from users where id = 1;
+----+--------+
| id | name   |
+----+--------+
|  1 | tanaka |
+----+--------+
1 row in set (0.00 sec)
```

ちょっとわかりにくいが、Aのupdateの結果に合わせて、select文の中で名前が変化してしまっている。
そのため、セッションAの処理がロールバックした場合に、トランザクションの処理中にselectした人はcommitされないupdateの中身を見ることになる