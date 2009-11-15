require 'rack'
module LifeForceAdminHelpers
  module Auth

    include Rack::Utils

    def login_required
      if session[:user]
        return true
      else
        session[:return_to] = request.fullpath
        redirect '/login'
        return false
      end
    end

    def current_user
      if session[:user]
        User.first(:id => session[:user])
      else
        GuestUser.new
      end
    end

    def logged_in?
      !!session[:user]
    end

    def use_layout?
      !request.xhr?
    end

    def authenticated
      logged_in?
    end

    def auth_required?(uri)

      return false if uri.starts_with?("/css") || uri.starts_with?("/js") || uri.starts_with?("/images") || uri.starts_with?("/setup")

      no_auth_paths = []
      no_auth_paths << "/login"
      no_auth_paths << "/forgot"
      !no_auth_paths.include?(uri)
    end
  end
end
