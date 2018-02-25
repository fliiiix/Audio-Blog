# encoding: UTF-8
require "fileutils"
require "soundcloud"
require "uri"

Sequel::Model.plugin :timestamps
Sequel::Model.plugin :tactical_eager_loading
Sequel.extension :pagination

DB.extension(:pagination)

# Social icons
DB.create_table? :social do
  primary_key :id
  String :key
  String :url
  Integer :position # 0 for header and 1 for footer
end

class Social < Sequel::Model(:social)
end


# about text
DB.create_table? :aboutPage do
  primary_key :id
  String :text

  DateTime :created_at
  DateTime :updated_at
end

class About < Sequel::Model(:aboutPage)
end


# deals text
DB.create_table? :dealsPage do
  primary_key :id
  String :text

  DateTime :created_at
  DateTime :updated_at
end

class Deals < Sequel::Model(:dealsPage)
end


# soundcloudToken
DB.create_table? :soundCloudToken do
  primary_key :id
  String :access_token, :require => true
  String :refresh_token, :require => true

  DateTime :created_at
  DateTime :updated_at
end

class SoundCloudToken < Sequel::Model(:soundCloudToken)
end

# Post
DB.create_table? :post do
  primary_key :id

  String :title, :require => true, :length => { :in => 5..40 }
  String :text, :require => true
  TrueClass :publish, default: true, :require => true
  String :type

  many_to_one :url

  many_to_one :musicPost
  many_to_one :videoPost

  DateTime :created_at
  DateTime :updated_at
end

class Post < Sequel::Model(:post)
  def created_at_formated
    created_at.strftime("%d %B %Y, %H:%M %p")
  end

  def embedded 
    if type == "video"
      '<div class="videoWrapper"><iframe id="ytplayer" type="text/html" width="560" height="349" src="https://www.youtube.com/embed/' + youtube_id(video.videoURL) + '" frameborder="0"></iframe></div>'
    elsif type == "music"
      '<iframe id="sc-widget" src="https://w.soundcloud.com/player/?url=' + music.soundCloudUrl + '&auto_play=false&auto_advance=true&buying=false&liking=false&download=true&sharing=true&show_artwork=true&show_comments=false&show_playcount=false&show_user=true&start_track=0" width="100%" height="166" scrolling="no" frameborder="no"></iframe>'
    end
  end

  def video
    @video_cache ||= VideoPost.find(id: videoPost)
  end

  def music
    @music_cache ||= MusicPost.find(id: musicPost)
  end

  private
  def youtube_id(youtube_url)
    if youtube_url[/youtu\.be\/([^\?]*)/]
      youtube_id = $1
    else
      # Regex from # http://stackoverflow.com/questions/3452546/javascript-regex-how-to-get-youtube-video-id-from-url/4811367#4811367
      youtube_url[/^.*((v\/)|(embed\/)|(watch\?))\??v?=?([^\&\?]*).*/]
      youtube_id = $5
    end
    return youtube_id
  end
end

Post.plugin :tactical_eager_loading

# MusicPost
DB.create_table? :musicPost do
  primary_key :id
  one_to_one :post

  String :soundCloudUrl, :require => true
  String :filePath, :require => true
  String :fileName, :require => true
  Integer :soundCloudId, :require => true 
end

class MusicPost < Sequel::Model(:musicPost)
  def before_validation
    if soundCloudUrl != nil
      return
    end
    lastToken = SoundCloudToken.last(:order => :created_at.asc)

    #get soundcloud client
    if lastToken != nil
      client = Soundcloud.new(:access_token => lastToken.access_token)
      
      if client.expired?
        #need to refresh the token!
        client = Soundcloud.new(:client_id => AppConfig["SoundCloudClientId"],
                    :client_secret => AppConfig["SoundCloudClientSecret"],
                    :refresh_token => lastToken.refresh_token)

        newToken = SoundCloudToken.new(:access_token => client.access_token, 
                                       :refresh_token => client.refresh_token)
        newToken.save
      end

      #File upload
      filename = rand(36**8).to_s(36) + fileName
      path = File.expand_path(File.dirname(__FILE__) + "/../public/uploads/#{filename}")

      begin
        FileUtils.cp(filePath, path)
        self[:filePath] = path
      rescue Exception => e
        errors.add(:soundCloudUrl, "Ex: " + e.to_s)
      end

      #upload to soundcloud
      begin
        track = client.post('/tracks', :track => {
          :title => fileName,
          :downloadable => true,
          :asset_data => File.new(path, 'rb')
        })
        self[:soundCloudUrl] = track.permalink_url
        self[:soundCloudId] = track.id
      rescue Exception => e
        errors.add(:soundCloudUrl, "Something unexpected went wrong, check your soundcloud account!")
      end
    else
      errors.add(:soundCloudUrl, "No Soundcloud token!")
    end
    super
  end
end

# MusicPost
DB.create_table? :videoPost do
  primary_key :id
  one_to_one :post

  String :videoURL, :require => true
end

class VideoPost < Sequel::Model(:videoPost)
  def validate
    super
    if videoURL == nil
      return
    end

    begin
      uri = URI.parse(videoURL)
      if uri.host.index("youtu") == nil
        errors.add(:videoURL, "It looks like your link is not from YouTube use one from youtube.com or youtu.be")
      end
    rescue Exception => e
      errors.add(:videoURL, "It don't look like a link :O")
    end
  end
end


# Url
DB.create_table? :url do
  primary_key :id
  one_to_one :post

  String :nice, :require => true
end

class Url < Sequel::Model(:url)

  def before_validation
    if nice == nil
      errors.add(:nice, "NO url for you!")
      return nil
    end
    url = sanitize(nice)
    counter = 0
    begin
      newUrl = url + (counter != 0 ? "-#{counter}" : "")
      counter += 1
    end while Url.first(:nice => newUrl) != nil
    self[:nice] = newUrl
  end

  private
  def sanitize(string)
    string.downcase.gsub("ö", "oe").gsub("ü", "ue").gsub("ä", "ae").gsub(/\W/,'-').squeeze('-').chomp('-').sub!(/^-*/, '')
  end
end
