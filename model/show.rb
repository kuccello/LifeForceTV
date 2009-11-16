module Lifeforce

  class ShowDate

    attr_accessor :year, :month, :day_of_week, :day_of_month, :timestamp

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

  class Show

    STATUS_PENDING = "pending"
    STATUS_LIVE = "live"
    STATUS_DELETED = "deleted"

    def uri
      "/#{self.url_id}"
    end

    def latest_episode
      # TODO -- this is not right
#      ShowDate.new(self.release_date_unix.to_i)
      ShowDate.new(Time.new.to_i)
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

    def Show.get_by_pid(pid)

      Lifeforce.transaction do

        Show[pid]

      end

    end

    def Show.get_by_url_id(uid)
      show = nil
      Lifeforce.transaction do
        Lifeforce.root.show.each do |s|
          show = s if s.url_id = uid
        end
      end
      show
    end

    # return a list of shows refined by the filteres passed in
    def self.list(filters={})
      found = []
      Xampl.transaction($transaction_context) do
        Lifeforce.root.show.each do |show|
          %w{ pending released deleted }.each do |filter|
            found << show.to_json if filters[filter.to_sym] && show.status == filters[filter.to_sym]
          end
        end
      end
      found
    end

    def remove
      self.status = 'deleted'
      Lifeforce.root.remove_show(self)
      schedule_a_deletion_if_needed
    end

    def should_schedule_delete?
      'deleted' == status
    end

    def get_json_episodes
      result = []
      self.episode.each do |episode|
        result << episode.to_json
      end
      result
    end

    # report self as json
    def to_json
      {:pid=>self.pid,
       :name=>self.name,
       :status=>self.status,
       :release_date=>self.release_date,
       :episodes=>self.get_json_episodes,
       :generas=>self.generas,
       :related_shows=>self.related_shows
      }
    end

    def generas
      generas = []
      self.genera.each do |genera|
        generas << {genera.pid.to_sym => genera.name}
      end
      generas
    end

    def related_shows
      related = []
      self.related_show.each do |related_show|
        related << {related_show.id.to_sym => related_show.show_pid}
      end
      related
    end

    Xampl::TokyoCabinetPersister.add_lexical_indexs(%w{ status name release_date_unix })

    def describe_yourself
      {
              'status' => self.status,
              'name' => self.name,
              'release_date_unix' => self.release_date_unix
      }
    end

    def Show.all
      Lifeforce.transaction do
        Lifeforce.root.show
      end
    end

    def Show.by_filter(status)
      Show.all.find_all {|show| show.status == status}
    end

    def Show.all_deleted
      self.by_filter(STATUS_DELETED)
    end

    def Show.all_pending
      self.by_filter(STATUS_PENDING)
    end

    def Show.all_live
      self.by_filter(STATUS_LIVE)
    end

    def episodes_by_filter(status)
      episodes = []
      self.episode.each do |episode|
        episodes << episode if episode.status == status
      end
      episodes
    end

    def sorted_episodes
      episodes = []
      le = live_episodes
      episodes = live_episodes.sort { |a, b| a.release_date_unix.to_i <=> b.release_date_unix.to_i } if le
      episodes.reverse
    end

    def live_episodes
      episodes_by_filter(Episode::STATUS_LIVE)
    end

    def pending_episodes
      episodes_by_filter(Episode::STATUS_PENDING)
    end

    def deleted_episodes
      episodes_by_filter(Episode::STATUS_DELETED)
    end

    # THIS IS BROKEN
    def episode_by_url_id(uid)
      episode = nil
      Lifeforce.transaction do
        self.episode.each do |ep|
          episode = ep if ep.url_id == uid
        end
      end
      episode
    end

    def find_season_of_episode(episode_passed_in)
      s = "1"
      self.season.each do |season|
        season.episode.each do |episode|
          if episode.pid == episode_passed_in then
            s = season.id
          end
        end
      end
      s
    end

    def update(params)
      puts "#{__FILE__}:#{__LINE__} #{__method__} #{params.inspect}"
      # get params:

      show_name = params[:show_name]
      show_description = params[:show_description]
      show_status = params[:show_status]
      show_release_date = params[:show_release_date]
      show_rating = params[:show_rating]
      show_url_id = params[:show_url_id]

      Lifeforce.transaction do
        self.name = show_name
        self.description = show_description
        self.status = show_status
        self.release_date = show_release_date
        self.rating = show_rating
        self.url_id = show_url_id
      end

      show_showcase_rm = params[:show_showcase_remove]
      show_showcase_add = params[:show_showcase_add]

      if show_showcase_rm then
        # remove from the showcase
        Showcase.default.remove_show(self.pid)
      end

      if show_showcase_add then
        # add to the showcase
        Showcase.default.add_show(self.pid)
      end

      dir = File.join(File.dirname(__FILE__), "../site/public/images/shows/#{self.pid}")


      if params[:show_big_image] &&
              (biu_tmp = params[:show_big_image][:tempfile]) &&
              (name = params[:show_big_image][:filename]) then

        fn_ext_split = name.split(".")
        fn_ext = fn_ext_split[fn_ext_split.size-1]

        # we have a big image file

        big_file = "#{dir}/big.#{fn_ext}"

        big = File.open( big_file, "wb" )

        while blk = biu_tmp.read(65536)
          big.write(blk)
        end

        Lifeforce.transaction do
          self.big_image = "/images/shows/#{self.pid}/big.#{fn_ext}"
        end
      end

      if params[:show_highlight_image] &&
              (miu_tmp = params[:show_highlight_image][:tempfile]) &&
              (name = params[:show_highlight_image][:filename]) then


        fn_ext_split = name.split(".")
        fn_ext = fn_ext_split[fn_ext_split.size-1]

        # we have a medium image file

        med_file = "#{dir}/med.#{fn_ext}"

        puts "#{__FILE__}:#{__LINE__} #{__method__} MEDIUM: #{med_file}"

        med = File.open( med_file, "wb" )

        while blk = miu_tmp.read(65536)
          med.write(blk)
        end

        Lifeforce.transaction do
          self.highlight_image = "/images/shows/#{self.pid}/med.#{fn_ext}"
        end
      end

      if params[:show_small_image] &&
              (siu_tmp = params[:show_small_image][:tempfile]) &&
              (name = params[:show_small_image][:filename]) then

        fn_ext_split = name.split(".")
        fn_ext = fn_ext_split[fn_ext_split.size-1]

        # we have a small image file

        small_file = "#{dir}/small.#{fn_ext}"

        small = File.open( small_file, "wb" )

        while blk = siu_tmp.read(65536)
          small.write(blk)
        end

        Lifeforce.transaction do
          self.small_image = "/images/shows/#{self.pid}/small.#{fn_ext}"
        end
      end

      if params[:show_poster_image] &&
              (siu_tmp = params[:show_poster_image][:tempfile]) &&
              (name = params[:show_poster_image][:filename]) then

        fn_ext_split = name.split(".")
        fn_ext = fn_ext_split[fn_ext_split.size-1]

        # we have a small image file

        poster_file = "#{dir}/poster.#{fn_ext}"

        poster = File.open( poster_file, "wb" )

        while blk = siu_tmp.read(65536)
          poster.write(blk)
        end

        Lifeforce.transaction do
          self.poster = "/images/shows/#{self.pid}/poster.#{fn_ext}"
        end
      end

      #  flash[:success] = "Success! You updated the show!"
      return true
    end
  end
end
