post '/login' do
  if params['username'] == AppConfig["User"] && params['pass'] == AppConfig["Pass"]
    session["isLogdIn"] = true
    redirect '/'
  else
    "Username or Password incorrect"
  end
end

get('/logout'){ session["isLogdIn"] = false ; redirect '/' }

get '/public' do
  'Anyone can see this'
end

get '/private' do
  protected!
  'For Your Eyes Only!'
end