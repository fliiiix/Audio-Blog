# encoding: UTF-8
require "sinatra"
require "soundcloud"
require_relative "model.rb"

@BlogTitel = "Music Blog"
@clinentId = ""
@clientSecret = ""

configure :development do
	MongoMapper.database = 'music'
	set :show_exceptions, true
end

configure :production do

end

get "/" do
	@posts = MusicPost.all()
	erb :index
end

get "/auth" do
	# create client object with app credentials
	client = Soundcloud.new(:client_id => @clinentId,
							:client_secret => @clientSecret,
							:redirect_uri => 'http://localhost:9393/authPoint')

	# redirect user to authorize URL
	puts client.authorize_url()
	redirect client.authorize_url()
end

get "/authPoint" do
	# create client object with app credentials
	client = Soundcloud.new(:client_id => @clinentId,
							:client_secret => @clientSecret,
							:redirect_uri => 'http://localhost:9393/authPoint')
	# exchange authorization code for access token
	code = params[:code]
	access_token = client.exchange_token(:code => code)
	token = SoundCloudToken.new(:access_token => access_token, :expires_in => params[:expires_in])
	token.save
	redirect "/add/music"
end

get "/add/:type" do |type|
	if type == "music"
		erb :addMusic
	end
end

post "/add/music" do
	if params[:soundFile] != nil && params[:soundSample] != nil
		post = MusicPost.new(:title => params[:title], 
						 :description => params[:description], 
						 :preis => params[:preis], 
						 :downloadFileName => params[:soundFile][:tempfile].to_path + "," + params[:soundFile][:filename].to_s,
						 :soundCloudUrl => params[:soundSample][:tempfile].to_path)
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