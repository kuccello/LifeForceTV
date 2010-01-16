module Lifeforce

  class EpisodeDate < HelperDate
  end

  class Episode
    STATUS_PENDING = "pending"
    STATUS_LIVE = "live"
    STATUS_DELETED = "deleted"

    def Episode.get_by_pid(pid)

      Lifeforce.transaction do

        Episode[pid]

      end

    end

    def ordered_credits
      ordered_credits = []

      crs = self.credit
      ordered_credits = crs.sort { |a, b| a.zorder.to_i <=> b.zorder.to_i } if crs
      ordered_credits.reverse

      ordered_credits
    end

    def ordered_crew
      oc = self.ordered_credits
      ocr = oc.select{|c| !c.is_cast? }
      ocr
    end

    def ordered_cast
      oc = self.ordered_credits
      ocr = oc.select{|c| c.is_cast? }
      ocr
    end

    def released_date
      EpisodeDate.new(self.release_date_unix.to_i)
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
        return true if g.pid==genera.pid
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

    def r_hour
      if self.release_hour && self.release_hour.length > 0
        return self.release_hour
      else
        "0"
      end
    end

    def r_minute
      if self.release_minute && self.release_minute.length > 0
        return self.release_minute
      else
        "0"
      end
    end

    def release_date_unix
      stamp = "#{self.release_date} at #{self.r_hour.to_i<10 ? '0' : ''}#{self.r_hour}:#{self.r_minute.to_i<10 ? '0' : ''}#{self.r_minute}"
#      puts "#{__FILE__}:#{__LINE__} #{__method__} STAMP: #{stamp}"
      Chronic.parse(stamp).to_i
    end

    def Episode.get_by_uid(uid)
      episode = nil
      Lifeforce.transaction do
        Lifeforce.root.episode.each do |ep|
          episode = ep if ep.url_id = uid
        end
      end
      episode
    end

    def remove
      self.status = 'deleted'
      Lifeforce.root.remove_episode(self)
      schedule_a_deletion_if_needed
    end

    def should_schedule_delete?
      'deleted' == status
    end

    # report self as json
    def to_json
      {:pid=>self.pid,
       :name=>self.name,
       :status=>self.status,
       :release_date=>self.release_date,
       :sequence_order=>self.sequence_order,
       :descriptions=>[{:long=>self.long_description, :short=>self.short_description}],
       :generas=>self.generas,
       :video=>self.video.last.to_json
      }
    end

    def generas
      self.genera
    end

#    def generas
#      generas = []
#      self.genera.each do |genera|
#        generas << {genera.pid.to_sym => genera.name}
#      end
#      generas
#    end

    def long_description
    end

    def long_description=(desc)
    end

    def short_description
    end

    def short_description=(desc)
    end

    # is the current date when compared to the release date of the episode valid to display this episode?
    def is_released?
      flag = false
      # parse out the release_date of this episode
      # compare it with the current date
      # if the pdate is less then current date then its released
      pdate = release_date_unix #Chronic.parse(self.release_date)
#      puts "#{__FILE__}:#{__LINE__} #{__method__} #{pdate} vs #{Time.new.to_i} -- released? #{(pdate.to_i < Time.new.to_i)}"
      flag = pdate.to_i < Time.new.to_i if pdate

      flag
    end

    def s
      Show.get_by_pid(self.show)
    end

    def uri
      "/#{s.url_id}/#{self.url_id}"
    end

    def running_time
      tstr = '00:00:00'
      begin
        len = self.length.to_i

        len_m = (len / 60).to_i
        len_r = (len % 60).to_i

        len_h = (len_r / 60).to_i
        len_r = (len_r % 60).to_i

        len_s = len_r

        hour = len_h
        minute = len_m
        seconds = len_s

        h = hour > 0 ? "#{hour<10?'0':''}#{hour}:" : ''

        tstr = "#{h}#{minute<10?'0':''}#{minute}:#{seconds<10?'0':''}#{seconds}"
      rescue => e
        tstr = "#{self.length}"
      end
      tstr
    end

    def update(params)
      show = s

      # process form save

      episode_name = params[:episode_name]
      episode_short_description = params[:episode_short_description]
      episode_long_description = params[:episode_long_description]
      episode_video_embed_hd = params[:episode_video_embed_hd]
      episode_video_embed_sd = params[:episode_video_embed_sd]
      episode_status = params[:episode_status]
      episode_release_date = params[:episode_release_date]
      episode_release_hour = params[:episode_release_hour]
      episode_release_minute = params[:episode_release_minute]

      episode_rating = params[:episode_rating]
      episode_language = params[:episode_language]
      episode_sequence = params[:episode_sequence]
      episode_length = params[:episode_length]
      episode_url = params[:episode_url]
      episode_poster_image = params[:episode_poster_image]
      episode_thumbnail_image = params[:episode_thumbnail_image]
      episode_hd_swf_url = params[:hd_swf_url]
      episode_sd_swf_url = params[:sd_swf_url]
      video_is_default = params[:video_is_default]

      ep_showcase_rm = params[:episode_showcase_remove]
      ep_showcase_add = params[:episode_showcase_add]

      if ep_showcase_rm then
        # remove from the showcase
        Showcase.default.remove_episode(self.pid)
      end

      if ep_showcase_add then
        # add to the showcase
        Showcase.default.add_episode(self.pid)
      end

      # TODO -- handle generas, credits, seasons

      # I don't think we need to process the individual videos....

      genera_list = params[:genera_list]

      new_generas = []
      if genera_list then
        sp_generas = genera_list.split(",")

        sp_generas.each do |g|
          gen = Genera.make_new_genera(g)
          gen.add_episode(self)
          new_generas << gen
        end
      end

      Lifeforce.transaction do

        self.name = episode_name
        self.hd_swf_url = episode_hd_swf_url
        self.sd_swf_url = episode_sd_swf_url
        self.status = episode_status
        self.release_date = episode_release_date
        self.release_hour = episode_release_hour
        self.release_minute = episode_release_minute
        self.sequence_order = episode_sequence
        self.url_id = episode_url
        self.content_rating = episode_rating
        self.language = episode_language
        self.length = episode_length
        self.embed_hd = episode_video_embed_hd
        self.embed_sd = episode_video_embed_sd
        self.description['long'].content = episode_long_description
        self.description['short'].content = episode_short_description
        self.video.each do |video|
          video.is_default = "true" if video_is_default == video.id
          video.is_default = "false" unless video_is_default == video.id
        end

        self.generas.each do |gx|
          self.do_remove_genera(gx)
        end

        new_generas.each do |gc|
          self << gc
          
        end
      end

      dir = File.join(File.dirname(__FILE__), "../site/public/images/shows/#{show.pid}/episodes/#{self.pid}")
      unless File.directory?( dir ) then
        # lets create it
        Dir.mkdir(dir)
      end

      if episode_poster_image &&
              (piu_tmp = episode_poster_image[:tempfile]) &&
              (name = episode_poster_image[:filename]) then

        fn_ext_split = name.split(".")
        fn_ext = fn_ext_split[fn_ext_split.size-1]

        # we have a big image file

        big_file = "#{dir}/poster.#{fn_ext}"

        big = File.open( big_file, "wb" )

        while blk = piu_tmp.read(65536)
          big.write(blk)
        end

        Lifeforce.transaction do
          self.poster = "/images/shows/#{show.pid}/episodes/#{self.pid}/poster.#{fn_ext}"
        end
      end

      if episode_thumbnail_image &&
              (tiu_tmp = episode_thumbnail_image[:tempfile]) &&
              (name = episode_thumbnail_image[:filename]) then

        fn_ext_split = name.split(".")
        fn_ext = fn_ext_split[fn_ext_split.size-1]

        # we have a big image file

        big_file = "#{dir}/thumbnail.#{fn_ext}"

        big = File.open( big_file, "wb" )

        while blk = tiu_tmp.read(65536)
          big.write(blk)
        end

        Lifeforce.transaction do
          self.poster = "/images/shows/#{show.pid}/episodes/#{self.pid}/thumbnail.#{fn_ext}"
        end
      end
    end

  end
end
