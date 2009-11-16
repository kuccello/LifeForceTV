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
    redirect '/admin/dashbard'
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

    if note.update(params) then
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

end
