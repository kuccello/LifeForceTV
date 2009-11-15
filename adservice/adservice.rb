require 'sinatra/base'

class LifeForceAdService < Sinatra::Base

  set :views, File.dirname(__FILE__) + '/views'
  set :public, File.dirname(__FILE__) + '/public'
  set :root, File.dirname(__FILE__)
  set :static, true

  get '/' do
    "Site not implemented"
  end

end
