class Model
    @@db_client = Mysql2::Client.new(
        host: "master",
        username: "root",
        password: 'secret',
        database: 'development'
    )

    def self.all()
        raise NotImplementedError
    end

    def self.find(id)
        raise NotImplementedError
    end
end