require 'uri'
require 'net/http'
require 'xml'
require 'nokogiri'
require 'digest/md5'
require 'fileutils'
require File.join(File.dirname(__FILE__), "../model/init" )

# This helps pull stuff from blip
module Lifeforce
  class Blip

    attr_accessor :show

    def process_rss(url_string, data={})

      begin
        url = URI.parse(url_string)

        req = Net::HTTP::Post.new(url.request_uri)

        req.set_form_data(data, '&')

        res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }

        case res
          when Net::HTTPSuccess
            # we got a response
            #puts "#{__FILE__}:#{__LINE__} #{__method__} #{res.body}"
            return itemize_rss(res.body)
          else
            # we failed to get a response we liked
            return []
        end
      end
    end

    def get_show(blip_show, show_title="Untitled", show_description="")
      show = Show.get_by_pid(blip_show)

      unless show then
        Lifeforce.transaction do
          show = Lifeforce.root.new_show(Lifeforce.pid_from_string(blip_show))
          show.status = Show::STATUS_PENDING
          show.name = "#{show_title}"
          show.release_date = "01/01/2037"
          show.release_date_unix = "#{Chronic.parse(show.release_date)}"
          show.url_id = show.pid
        end

        # ok, lets make sure that the show image directory exists
        show_dir = File.join(File.dirname(__FILE__), "../site/public/images/shows/#{blip_show.gsub(' ', '_')}")
        show_dir_exists = File.directory?( show_dir )

        unless show_dir_exists then
          # lets create it
          Dir.mkdir(show_dir)
          Dir.mkdir("#{show_dir}/episodes")

        end
      end
      @show = show
      show
    end

    def get_swf_code(blip_hash)
      "http://blip.tv/play/#{blip_hash}"
    end

    def get_embed_code(blip_hash)

      embed = <<-EMBED
<embed src="http://blip.tv/play/#{blip_hash}"
       type="Lifeforcelication/x-shockwave-flash"
       width="720"
       height="415"
       allowscriptaccess="always"
       allowfullscreen="true"></embed>
      EMBED

      embed
    end

    def get_big_image(img)
      "http://a.images.blip.tv/#{img}"
    end

    def download_image(src, dest_dir, dest_path)
      # TODO -- this needs to be cached etc.
      if src.starts_with?("http") then

        file_path = "#{src.downcase.gsub(/[ \/\\:\?'"%!@#\$\^&\*\(\)\+]/, '')}"

        location_of_file = "#{dest_dir}/#{file_path}"

        unless File.exists?(File.dirname(location_of_file))
          FileUtils.makedirs(File.dirname(location_of_file))
        end

        unless File.exists?( location_of_file)

          uri = URI.parse(src)
          Net::HTTP.start(uri.host) { |http|
            resp = http.get(uri.request_uri)
            open("#{dest_dir}/#{file_path}", "wb") { |file|
              file.write(resp.body)
            }
          }
        end
        return "#{dest_path}/#{file_path}"
      end
    end

    def itemize_rss(rss_body)
      items = []

      doc = Nokogiri::XML::Document.parse(rss_body)
      show_title = doc.root.at_xpath('//channel/title').content
      show_description = doc.root.at_xpath('//channel/description').content

      doc.xpath('//channel/item').each do |x_item|
        blip_pid = x_item.at_xpath('blip:show').content
        next if blip_pid.size == 0 # if there is no show then move on
        show = get_show(blip_pid, show_title, show_description) if blip_pid.size > 0
        items << show

        emb = ""
        temp = x_item.at_xpath('blip:embedLookup')
        emb = temp.content if temp

        swf_link = get_swf_code(emb)
        emb = get_embed_code(emb)


        epid = get_data(x_item, 'blip:item_id')
        dest_dir = File.join(File.dirname(__FILE__), "../site/public/images/shows/#{show.url_id}/episodes/#{epid}")
        dest_path = "/images/shows/#{show.url_id}/episodes/#{epid}"


        data = {
                :ep_pid => epid,
                :ep_big_img => download_image(get_data(x_item, "blip:thumbnail_src"), dest_dir, dest_path),
                :ep_small_img => download_image(get_data(x_item, "blip:smallThumbnail"), dest_dir, dest_path),
                :ep_lang => get_data(x_item, "blip:language"),
                :ep_runtime => get_data(x_item, "blip:runtime", "0"),
                :ep_rating => get_data(x_item, "blip:contentRating", "TV-G"),
                :ep_descrip => get_data(x_item, "blip:puredescription"),
                :ep_title => get_data(x_item, "title", "Untitled"),
                :ep_swf => swf_link
        }

        episode = get_episode(show, data[:ep_pid], data, emb)

        enc = x_item.xpath('enclosure')

        eg = x_item.xpath('media:group')

        cgs = eg.xpath('media:content')

        cgs.each do |cg|

          cg_hash = {}
          cg.attributes.each do |attr|
            cg_hash[attr[0]]=attr[1]
          end

          Lifeforce.transaction do
            begin
              cg_url = cg_hash["url"]
              video_id = Digest::MD5.hexdigest( cg_url )
              video = episode.video[video_id]
              unless video then
                video = episode.new_video(video_id)
                video.file_size   = cg_hash["fileSize"]
                video.height      = cg_hash["height"]
                video.width       = cg_hash["width"]
                video.is_default  = cg_hash["isDefault"]
                video.mime_type   = cg_hash["type"]
                video.url = cg_url

              end
            rescue => e
              puts "#{__FILE__}:#{__LINE__} #{__method__} ERROR: #{e}\n#{e.backtrace}"
            end
          end
        end
      end

      items

    end

    def get_episode(show, ep_pid, data, embed)
      ep = show.episode[ep_pid]
      unless ep then
        Lifeforce.transaction do

          begin
            ep = show.new_episode(ep_pid)

            ep.status = Episode::STATUS_PENDING
            ep.release_date = "0"
            ep.sequence_order = "0"
            ep.language = data[:ep_lang]
            ep.length = data[:ep_runtime]
            ep.content_rating = data[:ep_rating]
            ep.thumbnail = data[:ep_small_img]
            ep.poster = "http://a.images.blip.tv/#{data[:ep_big_img]}"
            ep.url_id = Lifeforce.pid_from_string(data[:ep_title])
            ep.name = data[:ep_title]
            ep.show = show.pid
            ep.embed_hd = embed
            ep.embed_sd = embed
            ep.hd_swf_url = data[:ep_swf]
            ep.sd_swf_url = data[:ep_swf]

            desc_short = ep.new_description('short')
            desc_short.content = data[:ep_descrip]

            desc_long = ep.new_description('long')
            desc_long.content = data[:ep_descrip]

            # ok, lets make sure that the show image directory exists
            show_dir = File.join(File.dirname(__FILE__), "../site/public/images/shows/#{show.pid}")
            show_dir_exists = File.directory?( show_dir )

            unless show_dir_exists then
              # lets create it
              Dir.mkdir(show_dir)
              Dir.mkdir("#{show_dir}/episodes")

              ep_dir = "#{show_dir}/episodes/#{ep.pid}"
              ep_dir_exists = File.directory?( ep_dir )

              unless ep_dir_exists then
                # lets create it
                Dir.mkdir(ep_dir)

              end

            end
          rescue => e
            puts "#{__FILE__}:#{__LINE__} #{__method__} #{e}\n#{e.backtrace}"
          end

        end
      end
      ep
    end

    def get_data(node, node_name, default="")
      data = default
      temp = node.at_xpath(node_name)
      data = temp.content if temp
      data
    end

    def capture(username, password, show)
      url = "http://#{show}.blip.tv/rss?userlogin=#{username}&password=#{password}"
      #puts "#{__FILE__}:#{__LINE__} #{__method__} CAPTURING: #{url}"
      resp = []
      begin
        resp = process_rss(url)
        puts "#{__FILE__}:#{__LINE__} #{__method__} RESP: #{resp} - URL: #{url}"
      rescue => e
        puts "#{__FILE__}:#{__LINE__} #{__method__} #{e} - #{e.backtrace}"
      end

      msg = SysMessage.new

      if resp && resp.size > 0 then
        msg.error = false
        msg.message = "Successfully parsed #{show}"
        msg.data = resp
      else

        puts "#{__FILE__}:#{__LINE__} #{__method__} RESPONSE: #{resp}"

        msg.error = true
        msg.message = "Error parsing #{show}"
        msg.data = nil
      end

      msg
    end

    def eat_file(file_string)
      itemize_rss(file_string)
    end

    def test_blip
      url = "http://byteclub.blip.tv/rss?userlogin=byteclub&password=bc4567"

      resp = process_rss(url)

      puts "#{__FILE__}:#{__LINE__} #{__method__} #{resp.inspect} #{resp.size}"
    end

  end
end
