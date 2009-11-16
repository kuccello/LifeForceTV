module LifeForceSiteHelpers
  module Content
    #
    # show_highlight(show)
    # =======================================
    # description:
    # ----------------
    # renders an entry
    #
    # params:
    # ----------------
    # show - the show object to hightlight
    #
    # returns:
    # ----------------
    # html
    def show_highlight(show)
      haml :'snippets/showhighlight', :layout=>false, :locals=>{:show=>show}
    end

    def partial(name, locals={})
      haml :"snippets/#{name}", :layout=>false, :locals=>locals
    end

    def nav_menu
      partial("nav_menu")
    end

    def default_showcase
      Lifeforce::Showcase.default
    end
  end
end
