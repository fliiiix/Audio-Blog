# encoding: UTF-8
require "mongo_mapper"
require "fileutils"
require "soundcloud"

class About
  include MongoMapper::Document

  key :text, String
  timestamps!
end

class SoundCloudToken
  include MongoMapper::Document

  key :access_token,  String, :require => true
  key :refresh_token, String, :require => true
end

class Post
  include MongoMapper::Document

  key :title, String, :require => true, :length => { :in => 5..40 }
  key :text,  String, :require => true
  one :url
  timestamps!
end

class MusicPost < Post
  include MongoMapper::Document

  key :preis,             Float,  :require => true, :numeric => true
  key :downloadFileName,  String, :require => true
  key :soundCloudUrl,     String, :require => true
  key :SoundCloudId,      Float,  :require => true, :numeric => true

  before_validation :uploadFile
  before_validation :uploadToSoundCloud

  private
  def uploadToSoundCloud
    lastToken = SoundCloudToken.last()
    if lastToken != nil
      client = Soundcloud.new(:access_token => lastToken.access_token)
      if !client#expired?
        #need to refresh the token!
        client = Soundcloud.new(:client_id => AppConfig["SoundCloudClientId"],
                    :client_secret => AppConfig["SoundCloudClientSecret"],
                    :refresh_token => lastToken.refresh_token)

        newToken = SoundCloudToken.new(:access_token => client.access_token, 
                         :refresh_token => client.refresh_token)
        newToken.save
      end
      puts soundCloudUrl
      # puts "file ist " + File.exist?(soundCloudUrl)
      track = client.post('/tracks', :track => {
        :title => "TestFile",
        :asset_data => File.new(soundCloudUrl, 'rb')
      })
      self[:soundCloudUrl] = track.permalink_url
      self[:SoundCloudId] = track.id
    else
      errors.add(:soundCloudUrl, "No Soundcloud token!")
    end
  end

  def uploadFile
    fileArray = downloadFileName.split(",")
    begin
      filename = rand(36**8).to_s(36) + fileArray[1]
      FileUtils.cp(fileArray[0], File.expand_path(filename, File.dirname(__FILE__) + "/public/uploads/"))
      self[:downloadFileName] = filename
    rescue Exception => e
      errors.add(:downloadFileName, "Ex: " + e.to_s + " Alles: " + downloadFileName.to_s)
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