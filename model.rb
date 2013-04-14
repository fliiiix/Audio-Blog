require "mongo_mapper"
require "fileutils"
require "soundcloud"

class SoundCloudToken
	include MongoMapper::Document

	key :access_token,  String, :require => true
	key :refresh_token, String, :require => true
end

class MusicPost
	include MongoMapper::Document

	key :title,				String, :require => true, :length => 5..25
	key :description, 		String, :length => 0..800
	key :preis, 			Float, :require => true, :numeric => true
	key :downloadFileName, 	String, :require => true
	key :soundCloudUrl, 	String, :require => true
	key :SoundCloudId, 		Float, :require => true, :numeric => true
	timestamps!

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
			puts File.path(soundCloudUrl)
			track = client.post('/tracks', :track => {
			  :title => title,
			  :asset_data => File.new(File.path(soundCloudUrl), 'rb')
			})
			set[:soundCloudUrl] = track.permalink_url
			set[:SoundCloudId] = track.id
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