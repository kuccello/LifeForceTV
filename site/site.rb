require 'sinatra/base'
require File.join(File.dirname(__FILE__), '../utils/krispythumb')

class LifeForceSite < Sinatra::Base

  set :views, File.dirname(__FILE__) + '/views'
  set :public, File.dirname(__FILE__) + '/public'
  set :root, File.dirname(__FILE__)
  set :static, true

  get '/' do
    haml :index
  end

  get '/scripts/timthumb.php' do
    kt = KrispyThumb.new(File.join(File.dirname(__FILE__), 'public'))
    uri = kt.process(request)
    puts "#{__FILE__}:#{__LINE__} #{__method__} URI: #{uri}"
    redirect uri
  end

  get '/1' do
    haml :'raw-haml/index', :layout=>false
  end

end
