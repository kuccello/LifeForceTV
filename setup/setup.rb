require 'sinatra/base'

require File.join(File.dirname(__FILE__), "../model/init")

class LifeForceSetup < Sinatra::Base

  set :views, File.dirname(__FILE__) + '/views'
  set :public, File.dirname(__FILE__) + '/public'
  set :root, File.dirname(__FILE__)
  set :static, true
  set :base_uri, "/"

  before do
    @current_uri = request.env["PATH_INFO"]
    LifeForceSetup.set :base_uri, request.env["REQUEST_PATH"].sub(@current_uri, "")
  end

  unless $LIFEFORCE_INSTALLED
    puts "================================================================"
    puts " LifeForce Configuration Setup:"
    puts "================================================================"

#    puts "#{__FILE__}:#{__LINE__} #{__method__} CAN I CREATE A MEMBER? #{Lifeforce::Member.new.inspect}"

    before do
      unless $LIFEFORCE_INSTALLED
        redirect '/setup/' if $lifeforce_configuration_setup_flag && !request.env["REQUEST_PATH"].include?('/setup')
      end
    end

    get '/' do
      puts "#{__FILE__}:#{__LINE__} #{__method__} HERE"
      unless $LIFEFORCE_INSTALLED
        haml :begin
      else
        haml :finish
      end
    end

    post '/' do
      unless $LIFEFORCE_INSTALLED
        # params - email, pass
        session[:setup] = {:admin=>{:email=>params[:email], :pass=>params[:pass]}}
        redirect '/setup/finish'
      else
        haml :finish
      end
    end

    get '/finish' do
      unless $LIFEFORCE_INSTALLED
        email, password = session[:setup][:admin][:email], session[:setup][:admin][:pass]
        Lifeforce::Member.create_default_administrator(email, password)

        # here we will create the installed.rb file
        local_filename = File.dirname(__FILE__)+"/../installed.rb"
        stamp = Time.now
        doc = <<-INSTALLED
# REMOVE THIS FILE TO HAVE SETUP RUN AGAIN
puts "=============================================="
puts " LifeForce v#{$LIFEFORCE_VERSION} has been setup - #{stamp.strftime("%b. %d, %Y")}"
puts "=============================================="
$LIFEFORCE_INSTALLED = true
$lifeforce_configuration_setup_flag = false
$transaction_context = "lifeforce-#{stamp.strftime('%Y-%m-%d-%H-%M-%S')}"

# PUTS SETTINGS IN PLACE FOR THIS INSTANCE OF THE APPLICATION
        INSTALLED
        File.open(local_filename, 'w') {|f| f.write(doc) }

        require File.join(File.dirname(__FILE__), '../_installed')

        session[:setup] = nil
      end
      haml :finish
    end
  end


end
