# encoding: UTF-8
require "mongo_mapper"
require "fileutils"
require "soundcloud"
require "uri"

class Social
  include MongoMapper::Document

  key :key, String
  key :url, String
end

class About
  include MongoMapper::Document

  key :text, String
  timestamps!
end

class SoundCloudToken
  include MongoMapper::Document

  key :access_token,  String, :require => true
  key :refresh_token, String, :require => true
  timestamps!
end

class Post
  include MongoMapper::Document

  key :title, String, :require => true, :length => { :in => 5..40 }
  key :text,  String, :require => true
  key :publish, Boolean, :require => true
  key :_type, String

  one :url
  timestamps!

  def created_at_formated()
    created_at.strftime("%d %B %Y, %H:%M %p")
  end
end

class MusicPost < Post
  include MongoMapper::Document

  key :soundCloudUrl,  String,  :require => true
  key :filePath,       String,  :require => true
  key :fileName,       String,  :require => true
  key :soundCloudId,   Integer, :require => true, :numeric => true

  before_validation :uploadToSoundCloud

  def embedded()
    '<iframe id="sc-widget" src="https://w.soundcloud.com/player/?url=' + soundCloudUrl + '&auto_play=false&auto_advance=true&buying=false&liking=false&download=true&sharing=true&show_artwork=true&show_comments=false&show_playcount=false&show_user=true&start_track=0" width="100%" height="166" scrolling="no" frameborder="no"></iframe>'
  end

  private
  def uploadToSoundCloud()
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
  end
end

class VideoPost < Post
  include MongoMapper::Document
  
  key :videoURL, String, :require => true

  validate :isYouTubeLink

  def embedded()
    '<div class="videoWrapper"><iframe id="ytplayer" type="text/html" width="560" height="349" src="http://www.youtube.com/embed/' + youtube_id(videoURL) + '" frameborder="0"></iframe></div>'
  end

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

  private
  def isYouTubeLink()
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

class Url
  include MongoMapper::Document

  key :nice, String, :require => true

  belongs_to :post
  before_validation :makeUrlNice

  private
  def makeUrlNice
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

  def sanitize(string)
    string.downcase.gsub("ö", "oe").gsub("ü", "ue").gsub("ä", "ae").gsub(/\W/,'-').squeeze('-').chomp('-').sub!(/^-*/, '')
  end
end