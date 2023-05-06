require_relative './Model'

class User < Model
	def self.all()
		@@db_client.query("SELECT * FROM users").map { |row| row }
	end
end
