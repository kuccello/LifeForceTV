module Lifeforce
  module ShowHelpers
    def deleted_shows
      Show.all_deleted
    end

    def pending_shows
      Show.all_pending
    end

    def live_shows
      Show.all_live
    end

    #
    # Returns the showcase episodes
    #
    def showcase
      s = Showcase.default
      unless s
        Showcase.create_default_showcase
        s = Showcase.default
      end
      s
    end

    def episdode_is_showcased(episode)

      return showcase.contains_episode?(episode) if showcase
      false
      
    end

    def show_is_showcased(show)

      return showcase.contains_show?(show) if showcase
      false

    end

    def note_is_showcased(note)
      return showcase.contains_note?(note) if showcase
      false
    end
  end
end
