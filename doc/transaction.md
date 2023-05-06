## トランザクションとは

DBの作業単位の事。トランザクションによって複数の変更がテーブルに行われた場合に、commitされると全ての変更が完了している事を表して、rollbackすると全ての変更が開始する前の状態に戻っている事を表す

## ACID特性

信頼性のあるトランザクションシステムが持つべき性質として提唱されている概念

A (atomicity) 原子性
 - これ以上分解されてはならないという単位の事。トランザクションが貼られた単位で処理が完全に成功するか、完全に実行前の状態になるというのが保証される事
 - commit -> 現在のトランザクションをコミットして、その変更を永続的なものにする
 - rollback -> 現在のトランザクションをロールバックして、その変更を取り消す

 [参考](https://dev.mysql.com/doc/refman/8.0/ja/commit.html#:~:text=COMMIT%20%E3%81%AF%E3%80%81%E7%8F%BE%E5%9C%A8%E3%81%AE%E3%83%88%E3%83%A9%E3%83%B3%E3%82%B6%E3%82%AF%E3%82%B7%E3%83%A7%E3%83%B3,%E7%84%A1%E5%8A%B9%E3%81%BE%E3%81%9F%E3%81%AF%E6%9C%89%E5%8A%B9%E3%81%AB%E3%81%97%E3%81%BE%E3%81%99%E3%80%82)

C (Consistency) 一貫性
 - トランザクションの実行によって、常に整合性が保たれている状態になること
 例: Aさんの銀行口座から、Bさんの銀行口座へ1000円振り込む際に、Aさんの口座には1000円ない場合に1000円引き落としがされない様にする事
     INT UNSIGNEDに対してマイナスの値を入れる事を禁止する事で担保できる
I (isolation)
 - 複数実行されているトランザクションから影響を受けない事
 - トランザクション分離レベルによってどのくらい分離するかが定義される
D (Durability)
 - トランザクションがcommitされた場合、その結果は失われない事を指す


[MySQL公式:  InnoDB および ACID モデル](https://dev.mysql.com/doc/refman/8.0/ja/mysql-acid.html)


## auto commit
MySQLではデフォルトの仕様としてauto commitが設定されている。
この設定は例えば

``` sql
INSERT INTO users (id, name) VALUES (100, 'hoge');
```

の様なSQLを実行した場合に、`commit`を打たなくても自動でcommitされる

このauto commitを回避するには、`begin`または `start transaction`を使用するかこの設定を切ると言う事で対応できる

auto commitの設定確認方法

```sql
SELECT @@autocommit;
```

