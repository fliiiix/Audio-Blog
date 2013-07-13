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
  @posts = GetPosts()
  erb :index
end

get "/page/?" do
  redirect "/"
end

get "/page/:id/?" do |pageId|
  @posts = GetPosts(pageId)
  erb :index
end

get "/add/:element/?" do |element|
  @element = element
  @posts = GetPosts()
  erb :index
end

def GetPosts(page = 1, elementPerPage = 10)
  @pageId = page.to_i
  if admin?
    posts = Post.paginate({
          :order => :created_at.desc,
          :per_page => elementPerPage,
          :page => page,
      })
    @postPagesTotal = (Post.all.count / elementPerPage)
  else
    posts = Post.where(:publish => true).sort(:created_at.desc) #MusicPost.all(:order => :created_at.desc) + Post.all(:order => :created_at.desc)
  end
  return posts
end

get "/about/?" do
  @about = About.last(:order => :created_at.asc)
  @aboutMenu = true
  erb :about 
end

get "/edit/about/?" do
  protected!
  @about = About.last(:order => :created_at.asc)
  erb :aboutEdit
end

post "/edit/about/?" do
  protected!
  about = About.new(:text => params[:mdtext])

  if about.save
    redirect "/about"
  else
    @meldung = "Error(s): " + post.errors.map {|k,v| "#{k}: #{v}"}.to_s
    erb :aboutEdit
  end
end

get "/edit/text/:id/?" do |id|
  protected!
  post = Post.find(id)
  @title = post.title
  @mdtext = post.text
  erb :addText
end

#rewrite!
post "/edit/text/:id/?" do |id|
  protected!
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

post "/add/text/?" do
  protected!
  post = Post.new(:title => params[:title], 
                  :text => params[:mdtext],
                  :publish => AppConfig["Status"],
                  :url => Url.new(:nice => params[:title]))
  if post.save
    redirect "/"
  end

  @meldung = "Error(s): " + post.errors.map {|k,v| "#{k}: #{v}"}.to_s
  @title = params[:title]
  @mdtext = params[:mdtext]
  @element = "text"

  @posts = GetPosts()
  erb :index
end

post "/add/music/?" do
  protected!
  if params[:soundSample] != nil
    filename = params[:soundSample][:filename]
    filepath = params[:soundSample][:tempfile].to_path
  else
    filename = ""
    filepath = ""
  end
  
  post = MusicPost.new(:title => params[:title],
                       :text => params[:mdtext],
                       :publish => AppConfig["Status"],
                       :fileName => filename,
                       :filePath => filepath,
                       :url => Url.new(:nice => params[:title]))
  if post.save
    redirect "/"
  end

  @meldung = "Error(s): " + post.errors.map {|k,v| "#{k}: #{v}"}.to_s
  @title = params[:title]
  @mdtext = params[:mdtext]
  @element = "music"

  @posts = GetPosts()
  erb :index
end

post "/add/video/?" do
  protected!
  post = VideoPost.new(:title => params[:title], 
                       :text => params[:mdtext],
                       :publish => AppConfig["Status"],
                       :videoURL => params[:videolink],
                       :url => Url.new(:nice => params[:title]))

  if post.save
    redirect "/"
  end

  @meldung = "Error(s): " + post.errors.map {|k,v| "#{k}: #{v}"}.to_s
  @title = params[:title]
  @mdtext = params[:mdtext]
  @videolink = params[:videolink]
  @element = "video"
  @posts = GetPosts()
  erb :index
end

get "/auth/?" do
  # create client object with app credentials
  client = Soundcloud.new(:client_id => AppConfig["SoundCloudClientId"],
                          :client_secret => AppConfig["SoundCloudClientSecret"],
                          :redirect_uri => 'http://localhost:9292/authPoint')

  # redirect user to authorize URL
  puts client.authorize_url()
  redirect client.authorize_url()
end

get "/authPoint/?" do
  # create client object with app credentials
  client = Soundcloud.new(:client_id => AppConfig["SoundCloudClientId"],
                          :client_secret => AppConfig["SoundCloudClientSecret"],
                          :redirect_uri => 'http://localhost:9292/authPoint')
  # exchange authorization code for access token
  auth = client.exchange_token(:code => params[:code])

  token = SoundCloudToken.new(:access_token => auth[:access_token], 
                              :refresh_token => auth[:refresh_token])
  token.save
  redirect "/"
end

get "/publish/:id" do |id|
  protected!
  p = Post.find(id)
  if p != nil
    p.publish = !p.publish
  end
  p.save
  redirect "/"
end

get "/id/:id/?" do |id|
  @text = Post.find(id)
  @music = MusicPost.find(id)
  erb :index
end

get "/:name/?" do |name|
  url = Url.first(:nice => name)
  halt 404 if url == nil
  
  if url.post != nil
    @post = url.post
  end

  if url.respond_to?(:music_post_id)
    @post = MusicPost.find(url.music_post_id)
  end
  
  if url.respond_to?(:video_post_id)
    @post = VideoPost.find(url.video_post_id)
  end

  halt 404 if !admin? && @post.publish == false 

  erb :index
end