## ロックについて

### なんのために必要か？
共有レコードに対しての変更に対して整合性を保持するために存在する。

### 3種類の不都合な現象

- Dirty Reads
 - commitされる前の変更を見る事ができる
- Non Repetable Reads
 - commitされた変更が同一トランザクション内で見る事ができる
- Phantom reads
 - 

詳しくは[こちら](https://qiita.com/momotaro98/items/ad859ec2934ee98540fb)

### トランザクション分離レベル