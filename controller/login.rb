get "/login" do
	erb :login
end

post '/login' do
  if params['username'] == AppConfig["User"] && params['pass'] == AppConfig["Pass"]
    session["isLogdIn"] = true
    redirect '/'
  else
    "Username or Password incorrect"
  end
end

get('/logout'){ session["isLogdIn"] = false ; redirect '/' }