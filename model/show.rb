require 'chronic'

module Lifeforce

  class ShowDate < HelperDate
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
      latest_ep = nil
      self.live_episodes.each do |ep|
#        puts "#{__FILE__}:#{__LINE__} #{__method__} #{ep.release_date_unix} - #{ep.name}"
        latest_ep = ep if latest_ep == nil
        latest_ep = ep if latest_ep.release_date_unix.to_i < ep.release_date_unix.to_i
      end

      sd = ShowDate.new(latest_ep.release_date_unix.to_i) if latest_ep
      sd = ShowDate.new(Time.new.to_i) unless latest_ep

#      puts "#{__FILE__}:#{__LINE__} #{__method__} SD: #{sd.timestamp} - #{self.name} - #{sd.inspect} - #{sd.month_str}, #{sd.day_of_month} ,#{sd.year}"

      sd
    end

    def released?
      puts "#{__FILE__}:#{__LINE__} #{__method__} #{self.release_date_unix}"
      (self.status == STATUS_LIVE) && (self.release_date_unix.to_i < Time.new.to_i)
    end

    def episode_count
      self.episode.size
    end

    def generas
      self.genera
    end

#    def has_genera?(genera_id)
#      flag = false
#      self.generas.each do |g|
#        flag = true if g.pid = genera_id
#      end
#      flag
#    end

    def highlight_description
      desc = ''
      desc = self.description['highlight'] if self.description
      if desc then
        return desc.content if desc.class.name != "String"
        return desc
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
          show = s if s.url_id == uid
        end
      end
      show
    end

    # return a list of shows refined by the filteres passed in
    def self.list(filters={})
      found = []
      Lifeforce.transaction do
        Lifeforce.root.show.each do |show|
          %w{ pending released deleted }.each do |filter|
            found << show.to_json if filters[filter.to_sym] && show.status == filters[filter.to_sym]
          end
        end
      end
      found
    end

    def self.find_by_genera(genera)
      found = []
      Lifeforce.transaction do
        Lifeforce.root.show.each do |s|
          found << s if s.has_genera?(genera)
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

    def generas_as_list
      str = ""
      flag = true
      generas.each do |i|
        str = "#{str}#{flag ? '' : ','}#{i.name}"
        flag = false
      end
      str
    end

#    def generas
#      generas = []
#      self.genera.each do |genera|
#        generas <<   [genera.pid , genera.name]
#      end
#      generas
#    end

    def has_genera?(genera)
      generas.each do |g|
        return true if genera && g.pid==genera.pid
      end
      false
    end

    def do_remove_genera(genera)
      if genera
        Lifeforce.transaction do
          self.remove_genera(genera)
        end
      end
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
      show_css = params[:show_css]

      genera_list = params[:genera_list]

      new_generas = []
      if genera_list then
        sp_generas = genera_list.split(",")

        sp_generas.each do |g|
          gen = Genera.make_new_genera(g)
          gen.add_show(self)
          new_generas << gen
        end
      end

      Lifeforce.transaction do
        self.name = show_name
        self.description = show_description
        self.status = show_status
        self.release_date = show_release_date
        # we need to chronic this date string...
        begin
        self.release_date_unix =  Chronic.parse(show_release_date).to_i  # Date.parse(show_release_date).to_i.to_s
        rescue => e
          puts "#{__FILE__}:#{__LINE__} #{__method__} ERROR PROCESSING DATE: #{show_release_date} -- #{e}"
        end
        self.rating = show_rating
        self.url_id = show_url_id

        self.generas.each do |gx|
          self.do_remove_genera(gx)
        end

        new_generas.each do |gc|
          self << gc

        end
        if self.css.first then
          self.css.first.content = show_css
        else
          css = self.new_css
          css.content = show_css
        end
        dir = File.join(File.dirname(__FILE__), "../site/public/css/shows")
        css_filepath = "#{dir}/#{self.pid}.css"
        if File.exists?(css_filepath)
          File.delete(css_filepath)
        end
        File.open( css_filepath, "w" ) do |cfile|
          cfile.write(show_css)
        end
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

      if params[:show_bg_image] &&
              (biu_tmp = params[:show_bg_image][:tempfile]) &&
              (name = params[:show_bg_image][:filename]) then

        fn_ext_split = name.split(".")
        fn_ext = fn_ext_split[fn_ext_split.size-1]

        # we have a big image file

        big_file = "#{dir}/bg.#{fn_ext}"

        big = File.open( big_file, "wb" )

        while blk = biu_tmp.read(65536)
          big.write(blk)
        end

        Lifeforce.transaction do
          self.bgimage = "/images/shows/#{self.pid}/bg.#{fn_ext}"
        end
      end

      #  flash[:success] = "Success! You updated the show!"
      return true
    end
  end
end
