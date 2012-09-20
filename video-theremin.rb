require 'sinatra'
require 'coffee-script'

get '/' do
  erb :index
end

get '/js/theremin.js' do
  coffee :"../js/theremin.js"
end

get '/js/init.js' do
  coffee :"../js/init.js"
end
