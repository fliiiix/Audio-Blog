Audio-Blog
==========
[![Build Status](https://travis-ci.org/fliiiix/Audio-Blog.png?branch=master)](https://travis-ci.org/fliiiix/Audio-Blog)

# The Config

```
cat $PROJECTDIR/config.yaml
production:
  SoundCloudClientId: xxx
  SoundCloudClientSecret: xxx
  SoundcloudRedirecURL: http://localhost:9292/authPoint
  BlogTitel: Music Blog
  Description: Bla bla bla
  User: test
  Pass: ChangeMe
  Social: ["Email", "Instagram", "Location", "Soundcloud", "Twitter", "Whatsapp", "Youtube", "Beatstarts", "Airbit"]
```

**Social**
Possible values are:

* Email
* Instagram
* Location
* Soundcloud
* Twitter
* Whatsapp
* Youtube
* Beatstarts
* Airbit


You can easily extend this just add a .png file to `public/img/social/` and add the file name to the Social config (your `config.yaml`)


### Environment 

The :environment defaults to the value of the RACK_ENV environment variable (ENV['RACK_ENV']), or :development when no RACK_ENV environment variable is set. You can configure different values for development and production.

For layout the awesome [pure](http://purecss.io/) framework.  
The icons are from [icomoon](http://icomoon.io/).

Credits for the image on /login from [flic.kr](http://www.flickr.com/photos/42931449@N07/5771025070/): [http://www.planetofsuccess.com/blog/](http://www.planetofsuccess.com/blog/)
