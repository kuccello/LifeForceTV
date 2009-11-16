require 'sinatra/base'
require File.join(File.dirname(__FILE__), '../utils/krispythumb')

require File.join(File.dirname(__FILE__), "../helpers/general")
require File.join(File.dirname(__FILE__), "../helpers/show")
require File.join(File.dirname(__FILE__), "helpers/show")

class LifeForceSite < Sinatra::Base

  set :views, File.dirname(__FILE__) + '/views'
  set :public, File.dirname(__FILE__) + '/public'
  set :root, File.dirname(__FILE__)
  set :static, true

  helpers Lifeforce::GeneralHelpers
  helpers Lifeforce::ShowHelpers

  helpers LifeForceSiteHelpers::Content

  not_found do
    "NOT FOUND!!! 404"
  end

  error do
    'Sorry there was a nasty error - ' + env['sinatra.error'].name
  end

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

  get '/shows' do

  end

  get '/generas' do
    generas = Lifeforce::Genera.all
    haml :generas, :locals=>{:generas=>generas}
  end

  get '/:show_url_id' do

    show = Lifeforce::Show.get_by_url_id(params[:show_url_id])

    haml :show, :locals=>{:show=>show}
  end

end
