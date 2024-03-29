# レプリケーション環境の構築

## 動かし方

- 起動方法

``` bash
docker-compose up -d
```
- 各コンテナへの入り方

``` bash
task exec -- master bash
task exec -- slave bash
```

## 背景
AWS Auroraでは、マルチAZ構成で同期レプリケーションを実施してくれたり、リードレプリカを作成して非同期のレプリケーションを実施して、負荷分散をしてくれている
この仕組みはAurora特有のものでMySQLではバイナリログレプリケーションが使用されるのですが、その挙動を実験できる環境を作りました

## 概要
- master側で実行したバイナリログをslave側にリレーログへコピーしてそこから同期を取る。

## 手順

###  レプリケーション用のユーザーを作成する(master)

``` bash
create user 'repl'@'%' identified by 'secret';
grant replication slave on *.* to 'repl'@'%';
```

`repl`というユーザーを作成して、レプリケーションを実行する権限を付与している。
ホスト名は今回 `%`にしているが、実際はIPアドレスを指定して制限することができる

### 認証方法の変更
`mysql_native_password`の認証方式に変更しないとslaveで再生する時にエラーが出るため、変更

```
ALTER USER 'yourusername'@'localhost' IDENTIFIED WITH mysql_native_password BY 'youpassword';
```

### バイナリログ情報を出力する (master)
``` bash
show master status\G;
```

すると下記のような情報が出てくる

```bash
*************************** 1. row ***************************
             File: d24b5effa743-bin.000003
         Position: 154
     Binlog_Do_DB:
 Binlog_Ignore_DB:
Executed_Gtid_Set:
```

この `File`と`Position`を後ほどslave側で指定するのでメモに取っておく。

ここで、既にデータがある場合は、dumpを取ってslave側に入れる必要がある。(事前にディレクトリは作成しておく)

```bash
mysqldump --single-transaction -u root -p sakila > /data/dump/sakila.dump
```

`--single-transaction`をつけると`BEGIN`を発行してスナップショットを取得するのでMVCCによって開始時点のスナップショットが取得されるので整合性が担保される
もう1つはこのオプションをつけていない場合ロックを取得して整合性を保とうとするため、パフォーマンスに影響が出る

### master側のサーバーの情報を設定する (slave)

```bash
change master to master_host="master",master_user="repl",master_password="secret", master_log_file="{バイナリログファイル名}", master_log_pos={バイナリログポジション}
```

 `master_log_file` に `show master status`コマンドで出てきた `File`の情報を追記する。
 `master_log_pos` に `show master status`コマンドで出てきた `Position`の情報を追記する。

### レプリケーションを開始する (slave)

```bash
start slave;
```

slaveの情報を見てみる

```bash
show slave status\G;
```

```bash
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: master //masterのホスト名が入る。今回はdockerのサービス名を指定している
                  Master_User: repl //master側で作成したユーザー
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: 5828dd0a6f73-bin.000003
          Read_Master_Log_Pos: 1112
               Relay_Log_File: d24b5effa743-relay-bin.000002
                Relay_Log_Pos: 1285
        Relay_Master_Log_File: 5828dd0a6f73-bin.000003
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 1112
              Relay_Log_Space: 1499
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 101
                  Master_UUID: c4946394-a8e9-11ed-9ce2-0242c0a88002
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
```

このリストの中でerrorが出ていたら、設定が間違っているのでログを見ながらトラブルシューティングをする。
特にエラーが出ていなかったらこれで、設定は完了。


### もしエラーが出たら

```
stop slave;
reset slave all;
設定を変更
start slave;
```

を実施して設定を見直す事ができる

## 検証

- master側でデータベースを作成して、slave側でもできていたらOK(insertでもなんでもOK)

```bash (master)
create database dev;
```

```bash (slave)
show databases;

+--------------------+
| Database           |
+--------------------+
| information_schema |
| dev                |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```

- バイナリログレプリケーションの遅延がない事をどうやったら確認できるか?

```bash
show slave status\G;
```

上記を実施して `Seconds_Behind_Master`が0だったらレプリカラグが無いので切り替え可能


## 前提知識
- バイナリログ
    - MySQLで行ったデータの変更情報をバイナリで出力するログの事で、master側で出力する必要がある。

- リレーログ
    - レプリケーションでslave側で設定が必要になる。master側ではバイナリログに出力される更新情報を、slave側ではリレーログに受け取って更新することになる。このようにコピーする事で、複数のslaveがいたとしても同期できるようになる。

細かくは [こちら](https://weblabo.oscasierra.net/mysql-log-1/) に書いてます

## 参考にしたサイト
[MySQLでMaster-Slave構成のレプリケーション設定](https://qiita.com/ksugawara61/items/fdd5ae9b78931540887f)
[公式ドキュメント](https://dev.mysql.com/doc/search/?d=171&p=1&q=%E3%83%AC%E3%83%97%E3%83%AA%E3%82%B1%E3%83%BC%E3%82%B7%E3%83%A7%E3%83%B3)

## 作ってみた感想
最初はmy.cnfの読み込み順番が分からず、どこに置いたら読み込んでくれるかなど地味に調査に時間がかかりました。
実際に運用が始まっていたら、mysqldumpでデータを移管してから実施しないといけないなど、気を遣う作業が結構あり
その作業が * リードレプリカを作る回数分必要になると思うのでその辺りを自動化してくれているAWSはとても便利だなと感じました。

次は2台、3台と増やして遊んでみたいなと思いました。

### masterとreplicaで名前が違うDBに流したい場合

```sql
CHANGE REPLICATION FILTER REPLICATE_REWRITE_DB = ((db1, db2));
```
これでmasterの`db1`からreplicaの`db2`にレプリケーションが実行される
