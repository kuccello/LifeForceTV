require 'sinatra/base'
require 'dirge'
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

  use SOC::McNamara, "#{File.dirname(__FILE__) + '/public/css'}"


  not_found do
    "NOT FOUND!!! 404"
  end

  error do
    'Sorry there was a nasty error - ' + env['sinatra.error'].name
  end

  get '/raw/:haml' do
    haml :"raw-haml/#{params[:haml]}", :layout=>false  
  end

  get '/' do
    haml :index
  end

  get '/about' do
    haml :about
  end
  get '/faq' do
    haml :faq
  end
  get '/advertising' do
    haml :advertising
  end
  get '/addshow' do
    haml :addshow
  end
  get '/contact' do
    haml :contact
  end
  get '/tos' do
    haml :tos
  end
  get '/privacy' do
    haml :privacy
  end

  get '/scripts/timthumb.php' do
    kt = KrispyThumb.new(File.join(File.dirname(__FILE__), 'public'))
    uri = kt.process(request)
#    puts "#{__FILE__}:#{__LINE__} #{__method__} URI: #{uri}"
    redirect uri
  end

  get '/1' do
    haml :'raw-haml/index', :layout=>false
  end

  get '/shows' do
    generas = Lifeforce::Genera.all
    genera = Lifeforce::Genera.get_by_pid(params[:genre])
    rating = params[:rating]
    order = params[:order]
    shows = all_released_shows unless genera
    
    shows = Lifeforce::Show.find_by_genera(genera) if genera

    if rating then
      new_shows = []
      shows.each do |sh|
        new_shows << sh if sh.rating == rating
      end
      shows = new_shows
    end

    if order then
      new_shows = []

      # ades - alpha desc
      # aass - alpha asc
      # nsf - new show first
      # nsl - new show last
      case order
        when "ades"
          new_shows = shows.sort { |a, b| a.name <=> b.name }
          shows = new_shows
        when "aass"
          new_shows = shows.sort { |a, b| a.name <=> b.name }
          shows = new_shows.reverse
        when "nsf"
          new_shows = shows.sort { |a, b| a.release_date_unix.to_i <=> b.release_date_unix.to_i }
          shows = new_shows.reverse
        when "nsl"
          new_shows = shows.sort { |a, b| a.release_date_unix.to_i <=> b.release_date_unix.to_i }
          shows = new_shows
      end
    end

    haml :shows, :locals=>{:shows=>shows, :generas=>generas}
  end

#  get '/generas' do
#    generas = Lifeforce::Genera.all
#    haml :generas, :locals=>{:generas=>generas}
#  end
#
#  get '/genera/:genera_id' do
#    # search for all shows and episodes that have the genera identified
#
#    shows = nil
#    episodes = nil
#
#    haml "NOT IMPLEMENTED YET"
#  end

  get '/:show_url_id/:episode_url_id' do

    show = Lifeforce::Show.get_by_url_id(params[:show_url_id])
    episode_id = params[:episode_url_id]

    haml :show, :locals=>{:show=>show, :episode_id=>episode_id, :override_style=>"/css/shows/#{(show ? show.pid : 'default')}.css"}
  end

  get '/:show_url_id' do

    show = Lifeforce::Show.get_by_url_id(params[:show_url_id])

    haml :show, :locals=>{:show=>show, :override_style=>"/css/shows/#{(show ? show.pid : 'default')}.css"}
  end

end
