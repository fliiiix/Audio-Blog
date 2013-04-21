# encoding: UTF-8
require "sinatra"
require "soundcloud"
require "yaml"
require "maruku"
require_relative "model.rb"

configure :development do
  AppConfig = YAML.load_file(File.expand_path("config.yaml", File.dirname(__FILE__)))["development"]
  MongoMapper.database = 'music'
  set :show_exceptions, true
end

configure :production do
  AppConfig = YAML.load_file(File.expand_path("config.yaml", File.dirname(__FILE__)))["production"]
end

get "/id/:id" do |id|
  @text = Post.find(id)
  @music = MusicPost.find(id)
  erb :index
end

get "/:name" do |name|
  @text = Url.first(:nice => name).post
  puts @text.text
  erb :index
end

get "/" do
  @posts = MusicPost.all
  @blog = Post.all
  erb :index
end

get "/add/:type" do |type|
  if type == "music"
    erb :addMusic
  end
  if type == "text"
    erb :addText
  end
end

post "/add/text" do
  post = Post.new(:title => params[:title], 
                      :text => params[:mdtext], 
                      :urls => [Url.new(:nice => params[:title])])
  if post.save
    @meldung = "successfully saved"
  else
    @meldung = "Error(s): " + post.errors.map {|k,v| "#{k}: #{v}"}.to_s
  end
  erb :addText
end

post "/add/music" do
  if params[:soundFile] != nil && params[:soundSample] != nil
    post = MusicPost.new(:title => params[:title], 
             :text => params[:description], 
             :preis => params[:preis], 
             :downloadFileName => params[:soundFile][:tempfile].to_path + "," + params[:soundFile][:filename].to_s,
             :soundCloudUrl => params[:soundSample][:tempfile].to_path,
             :urls => [Url.new(:nice => params[:title])])
    if post.save
      @meldung = "successfully saved"
    else
      @meldung = "Error(s): " + post.errors.map {|k,v| "#{k}: #{v}"}.to_s
    end
  else
    @meldung = "Error es muss ein Sample file und ein File ausgewählt werden!"
  end
  erb :addMusic
end

get "/auth" do
  # create client object with app credentials
  client = Soundcloud.new(:client_id => AppConfig["SoundCloudClientId"],
                          :client_secret => AppConfig["SoundCloudClientSecret"],
                          :redirect_uri => 'http://localhost:9393/authPoint')

  # redirect user to authorize URL
  puts client.authorize_url()
  redirect client.authorize_url()
end

get "/authPoint" do
  # create client object with app credentials
  client = Soundcloud.new(:client_id => AppConfig["SoundCloudClientId"],
                          :client_secret => AppConfig["SoundCloudClientSecret"],
                          :redirect_uri => 'http://localhost:9393/authPoint')
  # exchange authorization code for access token
  auth = client.exchange_token(:code => params[:code])
  
  if !client#expired?
    x = "true"
  else
    x = "false"
  end

  puts "expired: " + x
  puts "user: " + client.get('/me').username

  puts "access_token hash: " + auth[:access_token]
  puts "expires_in hash: " + auth[:expires_in].to_s
  puts "refresh_token hash: " + auth[:refresh_token]

  token = SoundCloudToken.new(:access_token => auth[:access_token], 
                              :refresh_token => auth[:refresh_token])
  token.save
  redirect "/add/music"
end