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

  before do
    $DESCRIPTION = $DEFAULT_DESC
    $KEYWORDS = $DEFAULT_KEY
    $TITLE = $DEFAULT_TITLE
  end

  not_found do
    "NOT FOUND!!! 404"
  end

  error do
    'Sorry there was a nasty error - ' + env['sinatra.error'].name
  end

#  get '/raw/:haml' do
#    haml :"raw-haml/#{params[:haml]}", :layout=>false
#  end

  get '/:show_name/rss' do
    content_type "application/rss+xml"
    <<-hhh
<?xml version="1.0"?>
<rss version="0.91">
  <channel>
    <title>ALL RSS FOR LIFEFORCE TV IS CURRENTLY OFF-LINE</title>
    <link>http://lifeforcetv.com</link>
    <description>Currently, rss is off line.</description>
    <language>en-us</language>
    <item>
      <title>No RSS for a little while</title>
      <description>We just switched server providers and some of our systems have yet to come back online.</description>
    </item>
  </channel>
</rss>

    hhh
  end

  get '/rss/news' do
    content_type "application/rss+xml"
    <<-hhh
<?xml version="1.0"?>
<rss version="0.91">
  <channel>
    <title>ALL RSS FOR LIFEFORCE TV IS CURRENTLY OFF-LINE</title>
    <link>http://lifeforcetv.com</link>
    <description>Currently, rss is off line.</description>
    <language>en-us</language>
    <item>
      <title>No RSS for a little while</title>
      <description>We just switched server providers and some of our systems have yet to come back online.</description>
    </item>
  </channel>
</rss>

    hhh
  end

  post '/send' do
    email_body = <<-eee
CONTACT FORM SUBMISSION
=========================
Date: #{Time.new}
Name: #{params[:name]}
Email: #{params[:email]}

Text:
----------------------
#{params[:text]}
----------------------
    eee
    begin
      Gelding.mail(:to => "mike@lifeforcefilms.com", :from => "no-reply@lifeforcetv.com", :subject => "[LFTV] Contact Submission", :body => email_body)
    rescue => e
      puts "#{__FILE__}:#{__LINE__} #{__method__} EMAIL FAILD TO SEND => #{e} --\n#{e.backtrace}"
    end

    flash[:email_sent] = "We have recevied your message! Thanks!"

    redirect '/contact'

  end

  get '/' do
    haml :index
  end

  get '/about' do
    $TITLE = "#{$DEFAULT_TITLE} - About"
    haml :about
  end
  get '/faq' do
    $TITLE = "#{$DEFAULT_TITLE} - Frequently Asked Questions"
    haml :faq
  end
  get '/advertising' do
    $TITLE = "#{$DEFAULT_TITLE} - Advertising With LifeForceTV"
    haml :advertising
  end
  get '/addshow' do
    $TITLE = "#{$DEFAULT_TITLE} - Add Your Show"
    haml :addshow
  end
  get '/contact' do
    $TITLE = "#{$DEFAULT_TITLE} - Contact Information"
    haml :contact
  end
  get '/tos' do
    $TITLE = "#{$DEFAULT_TITLE} - Terms Of Service"
    haml :tos
  end
  get '/privacy' do
    $TITLE = "#{$DEFAULT_TITLE} - Privacy Policy"
    haml :privacy
  end

  get '/scripts/timthumb.php' do
    kt = KrispyThumb.new(File.join(File.dirname(__FILE__), 'public'))
    uri = kt.process(request)
#    puts "#{__FILE__}:#{__LINE__} #{__method__} URI: #{uri}"
    redirect uri
  end

#  get '/1' do
#    haml :'raw-haml/index', :layout=>false
#  end

  get '/shows' do
    $TITLE = "#{$DEFAULT_TITLE} - Complete Show Lineup"
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

  get '/:show_url_id/episode/:episode_url_id' do
#    show = Lifeforce::Show.get_by_url_id(params[:show_url_id])
#    episode_id = params[:episode_url_id]
#
#    haml :show, :locals=>{:show=>show, :episode_id=>episode_id, :override_style=>"/css/shows/#{(show ? show.pid : 'default')}.css"}
    redirect "/#{params[:show_url_id]}/#{params[:episode_url_id]}", 301
  end

  get '/:show_url_id/:episode_url_id' do
#    puts "#{__FILE__}:#{__LINE__} #{__method__} -- "
#    request.env.each do |k,v|
#      puts "#{k}\t\t= #{v}"
#    end
#    puts "#{__FILE__}:#{__LINE__} #{__method__} --"

    pass if params[:show_url_id] == "images"

    show = Lifeforce::Show.get_by_url_id(params[:show_url_id])

    pass unless show

    episode_id = params[:episode_url_id]

    ep = show.episode_by_url_id(episode_id)

    $DESCRIPTION = "#{ep.description.first.content} - #{show.description}"
    generas = []
    ep.generas.each do |gx|
      generas << gx.name
    end
    $KEYWORDS = "#{ep.name}, #{generas.join(',')}, #{show.name}"

    $TITLE = "#{show.name}: Ep [#{ep.sequence_order}] #{ep.name} - #{$DEFAULT_TITLE}"

    haml :show, :locals=>{:show=>show, :episode_id=>episode_id, :override_style=>"/css/shows/#{(show ? show.pid : 'default')}.css"}
  end

  get '/:show_url_id' do

    show = Lifeforce::Show.get_by_url_id(params[:show_url_id])
    pass unless show
    $DESCRIPTION = "#{show.description}"
    generas = []
    show.generas.each do |gx|
      generas << gx.name
    end
    $KEYWORDS = "#{show.name}, #{generas.join(',')}"
    $TITLE = "#{show.name} - #{$DEFAULT_TITLE}"

    haml :show, :locals=>{:show=>show, :override_style=>"/css/shows/#{(show ? show.pid : 'default')}.css"}
  end

end
