# encoding: UTF-8
require "mongo_mapper"
require "fileutils"
require "soundcloud"
require "uri"

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
end

class MusicPost < Post
  include MongoMapper::Document

  key :soundCloudUrl,  String,  :require => true
  key :filePath,       String,  :require => true
  key :fileName,       String,  :require => true
  key :soundCloudId,   Integer, :require => true, :numeric => true

  before_validation :uploadToSoundCloud

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
          :title => "TestFile",
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

  before_validation :isYouTubeLink

  private
  def isYouTubeLink()
    if videoURL = nil || videoURL = ""
      return
    end
    uri = URI.parse(videoURL)
    youtubeURI = uri.host.include? "youtbe.com"
    youtubeShortURI = uri.host.include? "youtu.be"
    if !youtubeURI || !youtubeShortURI
      errors.add(:videoURL, "It looks like your link is not from youtube use one from youtube.com or youtu.be")
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