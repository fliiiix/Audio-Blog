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
  #DB = Sequel.sqlite
  DB = Sequel.connect("sqlite://test.db")
  set :show_exceptions, true
  Debug = true
end

configure :production do
  AppConfig = YAML.load_file(File.expand_path("../config.yaml", File.dirname(__FILE__)))["production"]

  # mysql2://user:pass@host/dbname
  DB = Sequel.connect(AppConfig['MYSQL_BLOG_URI'])
  Debug = false
end

configure :test do
  DB = Sequel.sqlite
  AppConfig = Hash.new
  AppConfig["BlogTitel"] = ""
  AppConfig["Description"] = ""
  AppConfig["User"] = ""
  AppConfig["Pass"] = ""
end
