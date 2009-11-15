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

  # This will be evaluated before static files are accessable too
  before do
    @current_uri = request.env["PATH_INFO"]
    LifeForceAdmin.set :base_uri, request.env["REQUEST_PATH"].sub(@current_uri,"")

    if auth_required?(@current_uri) && !authenticated
      redirect to_path("/login")
    end
  end

  get '/' do
    "Site not implemented"
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

    admin = Lifeforce::Member.authenticate_as_admin(email,password)


    if admin then
      session[:user_token] = admin.token
      redirect to_path('/dashboard')
    else
      # TODO -- log this somewhere ---- !!!!!
      STDERR.puts "Invalid Login Attempt: --- add details here"
      # FLASH MESSAGE -- BAD LOGIN
      flash[:error] = "Bad login attempt."
      haml :login,:layout=>false,:locals=>{:email=>email}
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
