require 'rack'
module LifeForceAdminHelpers
  module Link

    def to_path(uri)
      "#{options.base_uri}#{uri}"
    end

  end
end
