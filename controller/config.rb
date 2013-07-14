use Rack::Session::Pool

helpers do
  def admin? ; session["isLogdIn"] == true; end
  #def admin? ; true; end
  def protected! ; halt 401 unless admin? ; end
end

configure :development do
  AppConfig = YAML.load_file(File.expand_path("../config.yaml", File.dirname(__FILE__)))["development"]
  MongoMapper.database = 'music'
  set :show_exceptions, true
  set :views, Proc.new { File.join(root, "../views") }
  set :public_folder, Proc.new { File.join(root, "../public") }
end

configure :production do
  AppConfig = YAML.load_file(File.expand_path("../config.yaml", File.dirname(__FILE__)))["production"]
  set :views, Proc.new { File.join(root, "../views") }
  set :public_folder, Proc.new { File.join(root, "../public") }

  MongoMapper.connection = Mongo::Connection.new('localhost', AppConfig["MongoPort"].to_i)
  MongoMapper.database = 'music'
  MongoMapper.database.authenticate(AppConfig["MongoUser"], AppConfig["MongoPass"])
end