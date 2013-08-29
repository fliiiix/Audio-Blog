Audio-Blog
==========

~ in work ~
#The Config
<pre>
development:
  SoundCloudClientId: xxx
  SoundCloudClientSecret: xxx
  BlogTitel: Music Blog
  User:
  Pass:
production:
  SoundCloudClientId: xxx
  SoundCloudClientSecret: xxx
  BlogTitel: Music Blog
  User: test
  Pass: ChangeMe
  Mongo:
    Host: localhost
    Port: 20543
    User: user
    Pass: pass
</pre>

###Environment 
The :environment defaults to the value of the RACK_ENV environment variable (ENV['RACK_ENV']), or :development when no RACK_ENV environment variable is set. You can configure different values for development and production.

####development
`SoundCloudClientId:` The Client Id of your soundcloud app.  
`SoundCloudClientSecret:` The Secret of your soundcloud app.  
`BlogTitel:` The Title of your Blog. This value is used in header.  
`User:` The username of your Blog user account.  
`Pass:` The password of your Blog user account.  

#Build on top of
* [sinatra](http://www.sinatrarb.com/)
* [mongomapper](http://mongomapper.com/)
  * [mongoDB](http://www.mongodb.org/)
* [soundcloud](https://soundcloud.com/)

For layout the awesome [pure](http://purecss.io/) framework.  
The icons are from [icomoon](http://icomoon.io/).

Credits for the image on /login from [flic.kr](http://www.flickr.com/photos/42931449@N07/5771025070/): http://www.planetofsuccess.com/blog/
