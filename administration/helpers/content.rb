module LifeForceAdminHelpers
  module Content
    def sidebar
      haml :'snippets/sidebar',:layout=>false
    end

    def partial(name,locals={})
      haml :"snippets/#{name}", :layout=>false, :locals=>locals
    end

    def nav_menu
      partial("nav_menu")
    end
  end
end
