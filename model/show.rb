module Lifeforce

  class ShowDate

    @@months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Sept", "Oct", "Nov", "Dec"]
    @@days = ["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"]

    def initialize(timestamp)
      t = Time.at(timestamp)

      @month = t.month - 1
      @year = t.year
      @day_of_week = t.wday
      @day_of_month = t.day
      @timestamp = timestamp
    end

    def month_str
      @@months[@month]
    end

    def day_of_week_str
      @@days[@@day_of_week]
    end
  end

=begin
  <show pid=""
        name=""
        status="pending|released|deleted"
        release-date="2009-10-17 11:55"
        release-date-unix="epoc time stamp"
        big-image=""
        highlight-image=""
        small-image=""
        description=""
        rating=""
        poster=""
        url-id="">
=end
  class Show

    def uri
      "/#{url-id}"
    end

    def latest_episode
      ShowDate.new(self.release_date_unix.to_i)
    end

    def episode_count
      self.episode.size
    end

    def generas
      self.genera
    end

    def highlight_description
      desc = self.description['highlight']
      if desc then
        return desc.content
      else
        return <<-c
This show has no highlight description.
        c
      end
    end
  end
end
