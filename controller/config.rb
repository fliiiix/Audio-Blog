use Rack::Session::Pool

helpers do
  def admin? ; session["isLogdIn"] == true || Debug; end
  def protected! ; halt 401 unless admin? ; end
end

configure do
  set :views, Proc.new { File.join(root, "../views") }
  set :public_folder, Proc.new { File.join(root, "../public") }

  Debug = false
end

configure :development do
  AppConfig = YAML.load_file(File.expand_path("../config.yaml", File.dirname(__FILE__)))["development"]
  MongoMapper.database = 'music'
  set :show_exceptions, true
end

configure :production do
  AppConfig = YAML.load_file(File.expand_path("config.yaml", ENV["OPENSHIFT_DATA_DIR"]))["production"]

  MongoMapper.connection = Mongo::Connection.new(ENV["OPENSHIFT_MONGODB_DB_HOST"], ENV["OPENSHIFT_MONGODB_DB_PORT"].to_i)
  MongoMapper.database = ENV["OPENSHIFT_APP_NAME"]
  MongoMapper.database.authenticate(ENV["OPENSHIFT_MONGODB_DB_USERNAME"], ENV["OPENSHIFT_MONGODB_DB_PASSWORD"])
end

configure :test do
  MongoMapper.database = 'TestMusic'
  AppConfig = Hash.new
  AppConfig["BlogTitel"] = ""
  AppConfig["Description"] = ""
  AppConfig["User"] = ""
  AppConfig["Pass"] = ""
end
