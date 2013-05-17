# encoding: UTF-8
require "sinatra"
require "soundcloud"
require "yaml"
require "maruku"
require_relative "model.rb"
require_relative "config.rb"
require_relative "error.rb"
require_relative "login.rb"

get "/" do
  @posts = Post.all(:order => :created_at.desc) #MusicPost.all(:order => :created_at.desc) + Post.all(:order => :created_at.desc)
  erb :index
end

get "/about" do
  @about = About.last(:order => :created_at.asc)
  erb :about 
end

get "/edit/about" do
  protected!
  @about = About.last(:order => :created_at.asc)
  erb :aboutEdit
end

post "/edit/about" do
  protected!
  about = About.new(:text => params[:mdtext])

  if about.save
    redirect "/about"
  else
    @meldung = "Error(s): " + post.errors.map {|k,v| "#{k}: #{v}"}.to_s
    erb :aboutEdit
  end
end

get "/add/text" do
  erb :addMusic
end

get "/edit/text/:id" do |id|
  post = Post.find(id)
  @title = post.title
  @mdtext = post.text
  erb :addMusic
end

post "/edit/text/:id" do |id|
  post = Post.find(id)
  post.title = params[:title]
  post.text = params[:mdtext]

  if post.save
    @meldung = "successfully saved"
  else
    @meldung = "Error(s): " + post.errors.map {|k,v| "#{k}: #{v}"}.to_s
    @title = params[:title]
    @mdtext = params[:mdtext]
  end
end

post "/add/text" do
  post = Post.new(:title => params[:title], 
                  :text => params[:mdtext], 
                  :url => Url.new(:nice => params[:title]))
  if post.save
    @meldung = "successfully saved"
  else
    @meldung = "Error(s): " + post.errors.map {|k,v| "#{k}: #{v}"}.to_s
    @title = params[:title]
    @mdtext = params[:mdtext]
  end
  erb :addText
end

get "/add/music" do
  erb :addMusic
end

post "/add/music" do
  if params[:soundFile] != nil && params[:soundSample] != nil
    post = MusicPost.new(:title => params[:title], 
                         :text => params[:description], 
                         :preis => params[:preis], 
                         :downloadFileName => params[:soundFile][:tempfile].to_path + "," + params[:soundFile][:filename].to_s,
                         :soundCloudUrl => params[:soundSample][:tempfile].to_path,
                         :url => Url.new(:nice => params[:title]))
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

get "/id/:id" do |id|
  @text = Post.find(id)
  @music = MusicPost.find(id)
  erb :index
end

get "/:name" do |name|
  @post = Url.first(:nice => name).post
  erb :index
end