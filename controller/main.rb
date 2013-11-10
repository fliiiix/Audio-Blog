# encoding: UTF-8
require "sinatra"
require "soundcloud"
require "yaml"
require "maruku"
require "builder"
require_relative "model.rb"
require_relative "config.rb"
require_relative "error.rb"
require_relative "login.rb"

get "/" do
  @posts = GetPosts()
  erb :index
end

get "/rss/?" do
  @posts = Post.where(:publish => true).sort(:created_at.desc)
  builder :rss, locals: {title: AppConfig["BlogTitel"], description: AppConfig["Description"], baseUrl: request.base_url}
end

get "/archiv/?" do
  @posts = Post.where(:publish => true).sort(:created_at.desc)
  erb :archiv
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
    posts = Post.where(:publish => true).paginate({
          :order => :created_at.desc,
          :per_page => elementPerPage,
          :page => page,
      })
    @postPagesTotal = (Post.all.count / elementPerPage)
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

get "/addsocial" do
  protected!
  Social.new(:key => "facebook").save
  Social.new(:key => "youtube").save
  Social.new(:key => "gplus").save
  Social.new(:key => "flattr").save
  redirect "/social"
end

get "/social/?" do
  protected!
  erb :addSocialMedia, locals: {social: Social.all, saved: false}
end

post "/social/?" do
  protected!
  for account in params
    s = Social.first(:key => account[0]) == nil ? Social.new(:key => account[0]) : Social.first(:key => account[0])
    s.url = account[1]
    s.save!
  end
  erb :addSocialMedia, locals: {social: Social.all, saved: true}
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
                          :redirect_uri => AppConfig["SoundcloudRedirecURL"])

  # redirect user to authorize URL
  #puts client.authorize_url()
  redirect client.authorize_url()
end

get "/authPoint/?" do
  # create client object with app credentials
  client = Soundcloud.new(:client_id => AppConfig["SoundCloudClientId"],
                          :client_secret => AppConfig["SoundCloudClientSecret"],
                          :redirect_uri => AppConfig["SoundcloudRedirecURL"])
  # exchange authorization code for access token
  auth = client.exchange_token(:code => params[:code])

  token = SoundCloudToken.new(:access_token => auth[:access_token], 
                              :refresh_token => auth[:refresh_token])
  token.save
  redirect "/"
end

get "/post/delete/:id/?" do |id|
  protected!
  Post.destroy(id)
  redirect "/"
end

get "/post/edit/:id/?" do |id|
  protected!
  @postId = id
  p = Post.find(id)
  
  @title = p.title
  @mdtext = p.text

  if p._type == "Post"
    @element = "text"
  end
  if p._type == "MusicPost"
    @element = "music"
  end
  if p._type == "VideoPost"
    @element = "video"
    @videolink = p.videoURL
  end
  
  @posts = GetPosts()
  erb :index
end

post "/edit/:type/:id/?" do |type, id|
  p = Post.find(id)

  p.title = params["title"]
  p.text = params["mdtext"]

  if p._type == "VideoPost"
    p.videoURL = params["videolink"]
  end

  if p.save
    redirect "/"
  end

  @meldung = "Error(s): " + p.errors.map {|k,v| "#{k}: #{v}"}.to_s
  @title = params[:title]
  @mdtext = params[:mdtext]
  @videolink = params[:videolink]
  
  if p._type == "Post"
    @element = "text"
  end
  if p._type == "MusicPost"
    @element = "music"
  end
  if p._type == "VideoPost"
    @element = "video"
    @videolink = params[:videolink]
  end

  @posts = GetPosts()
  erb :index
end


get "/post/publish/:id/?" do |id|
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
  
  if url.post_id != nil
    @post = Post.find(url.post_id)
  elsif url.respond_to?(:music_post_id)
    @post = MusicPost.find(url.music_post_id)
  elsif url.respond_to?(:video_post_id)
    @post = VideoPost.find(url.video_post_id)
  end
  
  halt 404 if @post == nil
  halt 404 if !admin? && @post.publish == false

  erb :index
end