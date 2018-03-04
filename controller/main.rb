# encoding: UTF-8
require "sinatra"
require "soundcloud"
require "yaml"
require "maruku"
require "builder"
require "tilt/erb"
require "mysql2"
require "sequel"
require_relative "config.rb"
require_relative "model.rb"
require_relative "error.rb"
require_relative "login.rb"

get "/" do
  @about = About.order(:created_at).last
  @aboutMenu = true
  erb :about 
end

get "/deals/?" do
  @about = Deals.order(:created_at).last
  erb :about 
end

get "/blog/?" do
  @posts = GetPosts()
  erb :index
end

get "/rss/?" do
  @posts = Post.where(:publish => true).reverse(:created_at)
  builder :rss, locals: {title: AppConfig["BlogTitel"], description: AppConfig["Description"], baseUrl: request.base_url}
end

get "/archiv/?" do
  @posts = Post.where(:publish => true).reverse(:created_at)
  erb :archiv
end

get "/page/?" do
  redirect "/blog"
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

def GetPosts(page = 1, elementPerPage = 15)
  @pageId = page.to_i
  if admin?
    posts = Post.reverse(:created_at).paginate(@pageId, elementPerPage)
    @postPagesTotal = posts.page_count
  else
    posts = Post.where(:publish => true).reverse(:created_at).paginate(@pageId, elementPerPage)
    @postPagesTotal = posts.page_count
  end
  return posts.all
end

get "/about/?" do
  @about = About.order(:created_at).last
  @aboutMenu = true
  erb :about 
end

get "/edit/about/?" do
  protected!
  @about = About.order(:created_at).last
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

get "/social/?" do
  protected!
  erb :addSocialMedia, locals: {social: AppConfig["Social"], saved: false}
end

post "/social/?" do
  protected!
  for account in params.reject { |key, value| key.include? "-location" }
    s = Social.first(key: account[0]) == nil ? Social.new(key: account[0]) : Social.first(key: account[0])
    s.url = account[1]
    # 0 for header and 1 for footer
    s.position = (params.has_key? "#{account[0]}-location") ? 1 : 0
    s.save
  end
  erb :addSocialMedia, locals: {social: AppConfig["Social"], saved: true}
end

post "/add/text/?" do
  protected!
  url = Url.new(:nice => params[:title]).save
  post = Post.new(:title => params[:title], 
                  :text => params[:mdtext],
                  :publish => AppConfig["Status"],
                  :type => "text",
                  :url => url.id)
  if post.save
    redirect "/blog"
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
    soundcloudurl = nil
    soundcloudId = nil
  else
    filename = ""
    filepath = ""
    soundcloudurl = params[:soundCloudUrl]
    soundcloudId = -1
  end

  url = Url.new(:nice => params[:title]).save
  mpost = MusicPost.new(:fileName => filename,
                        :filePath => filepath,
                        :soundCloudUrl => soundcloudurl,
                        :soundCloudId => soundcloudId).save
  post = Post.new(:title => params[:title], 
                  :text => params[:mdtext],
                  :publish => AppConfig["Status"],
                  :type => "music",
                  :url => url.id,
                  :musicPost => mpost.id)

  if post.save
    redirect "/blog"
  end

  @meldung = "Error(s): " + post.errors.map {|k,v| "#{k}: #{v}"}.to_s
  @title = params[:title]
  @mdtext = params[:mdtext]
  @soundCloudUrl = params[:soundCloudUrl]
  @element = "music"

  @posts = GetPosts()
  erb :index
end

post "/add/video/?" do
  protected!
  url = Url.new(:nice => params[:title]).save
  vpost = VideoPost.new(:videoURL => params[:videolink]).save
  post = Post.new(:title => params[:title], 
                  :text => params[:mdtext],
                  :publish => AppConfig["Status"],
                  :type => "video",
                  :url => url.id,
                  :videoPost => vpost.id)

  if post.save
    redirect "/blog"
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
                          :redirect_uri => AppConfig["SoundcloudRedirecURL"])

  # redirect user to authorize URL
  puts client.authorize_url()
  redirect client.authorize_url()
end

get "/authPoint/?" do
  # create client object with app credentials
  client = Soundcloud.new(:client_id => AppConfig["SoundCloudClientId"],
                          :client_secret => AppConfig["SoundCloudClientSecret"],
                          :redirect_uri => AppConfig["SoundcloudRedirecURL"])
  # exchange authorization code for access token
  auth = client.exchange_token(:code => params[:code])

  SoundCloudToken.new(:access_token => auth[:access_token], 
                      :refresh_token => auth[:refresh_token]).save

  redirect "/blog"
end

get "/post/delete/:id/?" do |id|
  protected!
  Post.first(id: id).delete
  redirect "/blog"
end

get "/post/edit/:id/?" do |id|
  protected!
  @postId = id
  post = Post.first(id: id)
  
  @title = post.title
  @mdtext = post.text

  @element = post.type
  if post.type == "video"
    @videolink = post.video.videoURL
  end
  
  @posts = GetPosts()
  erb :index
end

post "/edit/:type/:id/?" do |type, id|
  p = Post.first(id: id)

  p.title = params["title"]
  p.text = params["mdtext"]

  
  if p.type == "video"
    puts params["videolink"]
    p.video.videoURL = params["videolink"]
    p.video.save
  end

  if p.save
    redirect "/blog"
  end

  @meldung = "Error(s): " + p.errors.map {|k,v| "#{k}: #{v}"}.to_s
  @title = params[:title]
  @mdtext = params[:mdtext]
  @videolink = params[:videolink]
  
  @element = post.type
  if post.type == "video"
    @videolink = post.video.videoURL
  end

  @posts = GetPosts()
  erb :index
end


get "/post/publish/:id/?" do |id|
  protected!
  p = Post.first(id: id)
  if p != nil
    p.publish = !p.publish
  end
  p.save
  redirect "/blog"
end

get "/id/:id/?" do |id|
  @text = Post.first(id: id)
  @music = MusicPost.first(:id => id)
  erb :index
end

get "/:name/?" do |name|
  @post = nil

  url = Url.first(nice: name)
  halt 404 if url == nil

  if url.post_id != nil
    @post = Post.first(id: url.post_id)
  end
   
  begin
    @post = MusicPost.first(id: url.music_post_id) if @post == nil
  rescue Exception => e
    @post = nil
  end

  begin
    @post = VideoPost.first(id: url.video_post_id) if @post == nil
  rescue Exception => e
    @post = nil
  end

  halt 404 if @post == nil
  halt 404 if !admin? && @post.publish == false
   
  erb :index
end
