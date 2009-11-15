require 'sinatra/base'

require File.join(File.dirname(__FILE__), "helpers/auth")
require File.join(File.dirname(__FILE__), "helpers/flash")
require File.join(File.dirname(__FILE__), "helpers/link")

class LifeForceAdmin < Sinatra::Base

  set :views, File.dirname(__FILE__) + '/views'
  set :public, File.dirname(__FILE__) + '/public'
  set :root, File.dirname(__FILE__)
  set :static, true
  set :base_uri, "/"

  helpers LifeForceAdminHelpers::Link
  helpers LifeForceAdminHelpers::Flash
  helpers LifeForceAdminHelpers::Auth


  # this will run once (or at least thats what I'm told)
  configure do
    #puts "#{__FILE__}:#{__LINE__} #{__method__} I AM CONFIGURING LifeForceAdmin"
  end

#  unless $LIFEFORCE_INSTALLED
#    before do
#      unless $LIFEFORCE_INSTALLED
#        redirect '/setup' if $lifeforce_configuration_setup_flag && !request.env["REQUEST_PATH"].include?('/setup')
#      end
#    end
#  end

  # This will be evaluated before static files are accessable too
  before do
    @current_uri = request.env["PATH_INFO"]
    LifeForceAdmin.set :base_uri, request.env["REQUEST_PATH"].sub(@current_uri, "")

    if auth_required?(@current_uri) && !authenticated
      puts "#{__FILE__}:#{__LINE__} #{__method__} #{@current_uri} -- is authenticated? #{authenticated}"
      redirect "/admin/login"
    end
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


end
