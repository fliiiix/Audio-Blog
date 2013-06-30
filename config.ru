$KCODE = 'u' if RUBY_VERSION < '1.9'
#\ -s puma
require './controller/main.rb'
run Sinatra::Application
