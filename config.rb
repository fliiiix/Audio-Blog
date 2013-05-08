use Rack::Session::Pool

helpers do
  def admin? ; session["user"] == AppConfig["User"] &&  session["pass"] == AppConfig["Pass"]; end
  def protected! ; halt [ 401, 'Not Authorized' ] unless admin? ; end
end

configure :development do
  AppConfig = YAML.load_file(File.expand_path("config.yaml", File.dirname(__FILE__)))["development"]
  MongoMapper.database = 'music'
  set :show_exceptions, true
end

configure :production do
  AppConfig = YAML.load_file(File.expand_path("config.yaml", File.dirname(__FILE__)))["production"]
end