Audio-Blog
==========
[![Build Status](https://travis-ci.org/fliiiix/Audio-Blog.png?branch=master)](https://travis-ci.org/fliiiix/Audio-Blog)

~ in work ~
#The Config

```
cat $OPENSHIFT_DATA_DIR/config.yaml
production:
  SoundCloudClientId: xxx
  SoundCloudClientSecret: xxx
  BlogTitel: Music Blog
  Description: Bla bla bla
  User: test
  Pass: ChangeMe
```

###Environment 
The :environment defaults to the value of the RACK_ENV environment variable (ENV['RACK_ENV']), or :development when no RACK_ENV environment variable is set. You can configure different values for development and production.

#Build on top of
* [sinatra](http://www.sinatrarb.com/)
* [mongomapper](http://mongomapper.com/)
  * [mongoDB](http://www.mongodb.org/)
* [soundcloud](https://soundcloud.com/)
* [Moment.js](http://momentjs.com/)

For layout the awesome [pure](http://purecss.io/) framework.  
The icons are from [icomoon](http://icomoon.io/). All social media icons are made by [@theR3m](http://twitter.com/theR3m)

Credits for the image on /login from [flic.kr](http://www.flickr.com/photos/42931449@N07/5771025070/): http://www.planetofsuccess.com/blog/
