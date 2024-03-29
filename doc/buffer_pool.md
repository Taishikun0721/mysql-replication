## バッファプールとは
InnoDBがアクセスした時にテーブル・インデックスの情報をキャッシュするメインメモリの領域の事を言う。
バッファプールを使用すると、メモリからその値を取得できるので処理速度が向上する。専用のデータベースサーバーを立てている場合は、メモリの約8割をこのバッファプールに当てられる。

[MySQL公式ドキュメント: バッファプール](https://dev.mysql.com/doc/refman/8.0/ja/innodb-buffer-pool.html#:~:text=%E3%83%90%E3%83%83%E3%83%95%E3%82%A1%E3%83%97%E3%83%BC%E3%83%AB%E3%81%AF%E3%80%81%20InnoDB%20%E3%81%8C,%E9%80%9F%E5%BA%A6%E3%81%8C%E5%90%91%E4%B8%8A%E3%81%97%E3%81%BE%E3%81%99%E3%80%82)

基本的にディスクアクセスを減らしたら、速度は向上するので可能な限りバッファプールにメモリを使いたい。
この時に変更する変数は `innodb_buffer_pool_size`となる
