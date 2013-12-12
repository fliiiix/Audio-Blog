get "/login/?" do
    @loginPage = true
    erb :login
end

post '/login/?' do
  if params['username'] == AppConfig["User"] && params['pass'] == AppConfig["Pass"]
    session["isLogdIn"] = true
    redirect '/'
  else
    erb :error401
  end
end

get('/logout/?'){ session["isLogdIn"] = false ; redirect '/' }