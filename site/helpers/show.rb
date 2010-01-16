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

    def search
      Lifeforce::SearchResults.default
    end

    def all_generas
      Lifeforce::Genera.all
    end

    def all_shows(params={})
      Lifeforce::Show.all
    end

    def all_released_shows(params={})
      Lifeforce::Show.all.select { |show| show.released?  }
    end

    def layout_ad
      Lifeforce::AdSense.get_layout_ad
    end

    def most_recent_episode(index=0)
      Lifeforce::Show.most_recent_episode(index)
    end

    def ad_300x300
      "<div class='ad_300x300'>300x300 Ad Here</div>"
    end
  end
end
