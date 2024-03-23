## phantom read

実際には`REPETABLE-READ`でも発生すると言われているが、[MVCC](https://dev.mysql.com/doc/refman/8.0/en/innodb-multi-versioning.html)という機構がMySQLには備わっているので、実際にこの現象が発生するのは、トランザクション分離レベルが `READ-COMMITED`の場合となる

[トランザクション分離レベル確認方法](https://marock.tokyo/2021/07/13/mysql-%E3%83%88%E3%83%A9%E3%83%B3%E3%82%B6%E3%82%AF%E3%82%B7%E3%83%A7%E3%83%B3%E5%88%86%E9%9B%A2%E3%83%AC%E3%83%99%E3%83%AB%E3%82%92%E7%A2%BA%E8%AA%8D%E3%81%99%E3%82%8B%E6%96%B9%E6%B3%95/)


■ トランザクション分離レベルを`READ-COMMITED`に変更
``` sql
mysql> SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
Query OK, 0 rows affected (0.01 sec)
```
■ 確認
``` sql
mysql> SELECT @@GLOBAL.tx_isolation, @@tx_isolation;
+-----------------------+----------------+
| @@GLOBAL.tx_isolation | @@tx_isolation |
+-----------------------+----------------+
| REPEATABLE-READ       | READ-COMMITTED |
+-----------------------+----------------+
1 row in set, 2 warnings (0.01 sec)
```

デフォルトでは`READ-COMMITED`の設定になっている


## `READ-COMMITED`の場合

トランザクションA
``` sql
mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from users;
+----+--------+
| id | name   |
+----+--------+
|  1 | hoge1  |
|  2 | hoge2  |
|  3 | hoge3  |
| 10 | hoge10 |
| 11 | hoge11 |
| 12 | hoge12 |
| 13 | hoge13 |
| 14 | hoge14 |
+----+--------+
8 rows in set (0.01 sec)

// この間でトランザクションBがcommitされる

mysql> select * from users;
+----+--------+
| id | name   |
+----+--------+
|  1 | hoge1  |
|  2 | hoge2  |
|  3 | hoge3  |
| 10 | hoge10 |
| 11 | hoge11 |
| 12 | hoge12 |
| 13 | hoge13 |
| 14 | hoge14 |
| 15 | hoge15 |
+----+--------+
9 rows in set (0.01 sec)
```


トランザクションB
``` sql
mysql> begin;
Query OK, 0 rows affected (0.01 sec)

mysql> insert into users (id, name) values (15, "hoge15");
Query OK, 1 row affected (0.01 sec)

mysql> commit;
Query OK, 0 rows affected (0.01 sec)
```

## `REPETABLE-READ`の場合

セッションA
``` sql
mysql> select * from users;
+----+--------+
| id | name   |
+----+--------+
|  1 | hoge1  |
|  2 | hoge2  |
|  3 | hoge3  |
| 10 | hoge10 |
| 11 | hoge11 |
| 12 | hoge12 |
| 13 | hoge13 |
| 14 | hoge14 |
| 15 | hoge15 |
+----+--------+
9 rows in set (0.01 sec)

// 同じくこの間でトランザクションBがcommitされる

mysql> select * from users;
+----+--------+
| id | name   |
+----+--------+
|  1 | hoge1  |
|  2 | hoge2  |
|  3 | hoge3  |
| 10 | hoge10 |
| 11 | hoge11 |
| 12 | hoge12 |
| 13 | hoge13 |
| 14 | hoge14 |
| 15 | hoge15 |
+----+--------+
9 rows in set (0.01 sec)
```

トランザクションB

```sql
mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> insert into users (id, name) values (16, "hoge16");
Query OK, 1 row affected (0.01 sec)

mysql> commit;
Query OK, 0 rows affected (0.00 sec)
```
