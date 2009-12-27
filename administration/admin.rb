require 'sinatra/base'

require File.join(File.dirname(__FILE__), "helpers/auth")
require File.join(File.dirname(__FILE__), "helpers/flash")
require File.join(File.dirname(__FILE__), "helpers/link")
require File.join(File.dirname(__FILE__), "helpers/content")

require File.join(File.dirname(__FILE__), "../helpers/general")
require File.join(File.dirname(__FILE__), "../helpers/show")

require File.join(File.dirname(__FILE__), '../utils/krispythumb')
require File.join(File.dirname(__FILE__), '../utils/bliptv')

class LifeForceAdmin < Sinatra::Base

  set :views, File.dirname(__FILE__) + '/views'
  set :public, File.dirname(__FILE__) + '/public'
  set :root, File.dirname(__FILE__)
  set :static, true
  set :base_uri, "/"

  helpers LifeForceAdminHelpers::Link
  helpers LifeForceAdminHelpers::Flash
  helpers LifeForceAdminHelpers::Auth
  helpers LifeForceAdminHelpers::Content

  helpers Lifeforce::GeneralHelpers
  helpers Lifeforce::ShowHelpers


  # this will run once (or at least thats what I'm told)
  configure do
    #puts "#{__FILE__}:#{__LINE__} #{__method__} I AM CONFIGURING LifeForceAdmin"
  end

  # This will be evaluated before static files are accessable too
  before do
    @current_uri = request.env["PATH_INFO"]
    LifeForceAdmin.set :base_uri, request.env["REQUEST_PATH"].sub(@current_uri, "")

    if auth_required?(@current_uri) && !authenticated
      puts "#{__FILE__}:#{__LINE__} #{__method__} #{@current_uri} -- is authenticated? #{authenticated}"
      redirect "/admin/login"
    end
  end

  not_found do
    "NOT FOUND!!! 404"
  end

  error do
    'Sorry there was a nasty error - ' + env['sinatra.error'].name
  end

  get '/' do
    redirect '/admin/dashboard'
  end

  # deliver the login page
  get '/login' do
    haml :login, :layout=>false
  end

  # process the login attempt
  post '/login' do
    # params : email & pass
    email = params[:email]
    password = params[:pass]

    admin = Lifeforce::Member.authenticate_as_admin(email, password)

    if admin then
      session[:user] = admin.token
      redirect to_path('/dashboard')
    else
      # TODO -- log this somewhere ---- !!!!!
      STDERR.puts "Invalid Login Attempt: --- add details here"
      # FLASH MESSAGE -- BAD LOGIN
      flash[:error] = "Bad login attempt."
      haml :login, :layout=>false, :locals=>{:email=>email}
    end

  end

# process logout
  get '/logout' do
    session[:user] = nil
    redirect to_path('/dashboard')
  end

# deliver the forgot password form
  get '/forgot' do

  end

# handle the forgot password form
  post '/forgot' do

  end

  get '/dashboard' do
    haml :dashboard
  end

  get '/showcase' do
    haml :showcase
  end

  post '/showcase/adjust/:showcase_episode_id' do
    action = params[:action]
    ep_id = params[:showcase_episode_id]
    case action
      when 'up' then
        Lifeforce::Showcase.default.move_episode_up( ep_id)
      when 'down' then
        Lifeforce::Showcase.default.move_episode_down( ep_id)
      when 'remove' then
        Lifeforce::Showcase.default.remove_episode( ep_id)
    end
    haml :showcase
  end

  post '/showcase/adjust-show/:showcase_show_id' do
    action = params[:action]
    show_id = params[:showcase_show_id]
    case action
      when 'up' then
        Lifeforce::Showcase.default.move_show_up( show_id)
      when 'down' then
        Lifeforce::Showcase.default.move_show_down( show_id)
      when 'remove' then
        Lifeforce::Showcase.default.remove_show( show_id)
    end
    haml :showcase
  end

  get '/notes' do
    notes = Lifeforce::Note.all
    haml :notes, :locals=>{:notes=>notes}
  end

  get '/note/new' do
    note = Lifeforce::Note.make_new_note
    redirect "/admin/note/#{note.pid}"
  end

  get '/note/:note_pid' do
    note = Lifeforce::Note.get_by_pid(params[:note_pid])
    haml :note, :locals=>{:note=>note}
  end

  post '/note/:note_pid' do
    note = Lifeforce::Note.get_by_pid(params[:note_pid])
    puts "#{__FILE__}:#{__LINE__} #{__method__} HERE"
    if note.update(params) then
      puts "#{__FILE__}:#{__LINE__} #{__method__} HERE"
      flash[:success] = "Successfully updated note."
    else
      flash[:error] = "Failed to update note."
    end

    haml :note, :locals=>{:note=>note}
  end

  get '/shows' do


    shows = Lifeforce::Show.all

    haml :shows, :locals => { :shows => shows }
  end

  get '/show/add-bliptv' do
    haml :bliptv
  end

  get '/show/add-file' do
    haml :rss_file
  end

  post '/show/add-blip' do


    blip_usr = params["blip-user"]
    blip_pass = params["blip-pass"]
    blip_show = params["blip-show-name"]

    blip = Lifeforce::Blip.new

    msg = blip.capture(blip_usr, blip_pass, blip_show)

    if msg.error then
      flash[:error] = "There was a problem pulling the show! - #{msg.message}"
      haml :bliptv
    else
      flash[:message] = "Successfully pulled show!"
      redirect "/admin/show/#{blip.show.pid}/edit"
    end
  end

  post '/show/add-file' do

    blip = Lifeforce::Blip.new
    
    if params['blip-rss'] &&
            (biu_tmp = params['blip-rss'][:tempfile]) &&
            (name = params['blip-rss'][:filename]) then

      file = ""
      while blk = biu_tmp.read(65536)
        file += blk
      end
      blip.eat_file(file)
    end
    flash[:message] = "Successfully processed show!"
    haml :rss_file
  end

  get '/show/:show_pid/edit' do


    show_pid = params[:show_pid]
    show = Lifeforce::Show.get_by_pid(show_pid)

    pass unless show

    haml :show, :locals => {:show=>show}
  end

  post '/show/:show_pid/edit' do


    show_pid = params[:show_pid]
    show = Lifeforce::Show.get_by_pid(show_pid)
    pass unless show

    begin
      # get params:

      success = show.update(params)

      flash[:success] = "Success! You updated the show!" if success
      flash[:error] = "Failed to update show." unless success
    rescue => e
      flash[:error] = "ERROR: there was a serious problem -- #{e}"
    end

    haml :show, :locals => {:show=>show}
  end

  get '/episode/:episode_pid/edit' do


    episode_pid = params[:episode_pid]
    episode = Lifeforce::Episode.get_by_pid(episode_pid)

    show = Lifeforce::Show.get_by_pid(episode.show)

    pass unless episode

    haml :episode, :locals => {:episode=>episode, :show=>show}
  end

  post '/episode/:episode_pid/edit' do


    episode_pid = params[:episode_pid]
    episode = Lifeforce::Episode.get_by_pid(episode_pid)

    pass unless episode

    begin

      episode.update(params)

      flash[:success] = "Successfully updated episode!"
    rescue => e
      flash[:error] = "ERROR: there was a problem - #{e}"
    end

    haml :episode, :locals => {:episode=>episode, :show=>episode.s}

  end

  get '/generas' do
    generas = Lifeforce::Genera.all
#    puts "#{__FILE__}:#{__LINE__} #{__method__} #{generas[0].pp_xml}"
    haml :generas, :locals => {:generas=>generas}
  end

  post '/genera/new' do
    name = params[:genera_name]
    genera = Lifeforce::Genera.make_new_genera( name)
    flash[:success] = "Created gener #{name}" if genera
    redirect '/admin/generas'
  end

  get '/genera/:pid/delete' do
    genera = Lifeforce::Genera.get_by_pid(params[:pid])
    if genera then
      Lifeforce::Genera.remove_from_system(genera)

    end
    redirect '/admin/generas'
  end

  get '/ads' do

    ads = Lifeforce.root.ad_sense

    haml :ads, :locals=>{:ads=>ads}
  end

  get '/ad/:ad_pid' do
    ad = Lifeforce::AdSense.get_by_pid(params[:ad_pid])
    
    unless ad then
      ad = Lifeforce::AdSense.make_ad
    end

    haml :ad, :locals=>{:ad=>ad}
  end

  get '/ad/delete/:ad_pid' do
    ad = Lifeforce::AdSense.get_by_pid(params[:ad_pid])

    if ad then
      Lifeforce::AdSense.delete_this_ad(ad)
    end

    flash[:message] = "Deleted ad"
    ads = Lifeforce.root.ad_sense

    haml :ads, :locals=>{:ads=>ads}
  end

  post '/ad/:ad_pid' do
    ad = Lifeforce::AdSense.get_by_pid(params[:ad_pid])
    ad.update_data(params)
    haml :ad, :locals=>{:ad=>ad}
  end

  get '/credit/show/:show_pid/new' do
    show_pid = params[:show_pid]
    show = Lifeforce::Show.get_by_pid(show_pid)

    cr = Lifeforce::Credit.make_new_show_credit(show,params)
    haml :credit, :locals=>{:credit=>cr,:kind=>"show",:val=>show_pid}
  end

  get '/credit/episode/:episode_pid/new' do
    episode_pid = params[:episode_pid]
    episode = Lifeforce::Episode.get_by_pid(episode_pid)

    cr = Lifeforce::Credit.make_new_epidose_credit(episode,params)
    puts "#{__FILE__}:#{__LINE__} #{__method__} CR: #{cr.pid}"
    haml :credit, :locals=>{:credit=>cr,:kind=>"episode",:val=>episode_pid}
  end

  get '/credit/show/:show_pid/:credit_pid' do
    credit_pid = params[:credit_pid]
    credit = Lifeforce::Credit.get_by_pid(credit_pid)
    show_pid = params[:show_pid]

    haml :credit, :locals=>{:credit=>credit,:kind=>"show",:val=>show_pid}
  end

  get '/credit/episode/:episode_pid/:credit_pid' do
    credit_pid = params[:credit_pid]
    credit = Lifeforce::Credit.get_by_pid(credit_pid)
    episode_pid = params[:episode_pid]
    haml :credit, :locals=>{:credit=>credit,:kind=>"episode",:val=>episode_pid}
  end

  post '/credit/:credit_pid' do
    credit_pid = params[:credit_pid]
    credit = Lifeforce::Credit.get_by_pid(credit_pid)
    credit.update_data(params)
    flash[:success] = "Updated Credit!"

    redirect "/admin/show/#{params[:val]}/edit" if params[:kind] == "show"
    redirect "/admin/episode/#{params[:val]}/edit" if params[:kind] == "episode"
    "OPPS! HEY you forgot to inlude the kind and val!"
  end

  get '/credit/:credit_pid/show/:show_pid/delete' do
    show_pid = params[:show_pid]
    show = Lifeforce::Show.get_by_pid(show_pid)
    credit_pid = params[:credit_pid]
    credit = Lifeforce::Credit.get_by_pid(credit_pid)
    Lifeforce::Credit.remove_credit_from_show(show,credit)
    flash[:message] = "credit deleted"
    redirect "/admin/show/#{show_pid}/edit"
  end
  get '/credit/:credit_pid/episode/:episode_pid/delete' do
    episode_pid = params[:episode_pid]
    episode = Lifeforce::Episode.get_by_pid(episode_pid)
    credit_pid = params[:credit_pid]
    credit = Lifeforce::Credit.get_by_pid(credit_pid)
    Lifeforce::Credit.remove_credit_from_episode(episode,credit)
    flash[:message] = "credit deleted"
    redirect "/admin/episode/#{episode_pid}/edit"
  end

end
