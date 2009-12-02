class KrispyThumb
  # base_path is the file system path to the images directory
  def initialize(base_path=File.dirname(__FILE__))
    @base_path = base_path
  end

  def append_filename(filename, suffix)
    extrac = filename.split('.')
    extrac[-2] += suffix
    extrac.join('.')
  end

  def process(request)
    @request = request
    src = request.params['src']
    path = "#{@base_path}#{src}" #src #clean_source(src)
    last_modified = File.new(path).mtime

    new_width = request.params['w'] ? request.params['w'].to_i : 0
    new_height = request.params['h'] ? request.params['h'].to_i : 0
    zoom_crop = request.params['zc'] ? request.params['zc'].to_i : 0
    zoom_crop_height = request.params['zh'] ? request.params['zh'].to_i : 100
    zoom_crop_width = request.params['zw'] ? request.params['zw'].to_i : 100
    zoom_crop_width_offset = request.params['zow'] ? request.params['zow'].to_i : 0
    zoom_crop_height_offset = request.params['zoh'] ? request.params['zoh'].to_i : 0
    force_rebuild = request.params['force'] ? request.params['force'] : false
    quality = request.params['q'] ? request.params['q'].to_i : 80
    filters = request.params['f']


    if new_width == 0 && new_height == 0 then
      new_width = 100
      new_height = 100
    end

    wh = "-#{new_width}x#{new_height}"
    append_filename = append_filename(path, wh)
    if File.exists?(append_filename) && force_rebuild
      begin
        puts "#{__FILE__}:#{__LINE__} #{__method__} #{last_modified.to_i} - #{Time.new.to_i} = #{Time.new.to_i - last_modified.to_i} DELETING FILE #{append_filename}"
        File.delete(append_filename)
      rescue
      end
    end

    unless File.exists?(append_filename)

      convert = "convert #{path} -resize #{wh} #{append_filename}"


      begin
        system( convert )
        if zoom_crop == 1 then
          puts "#{__FILE__}:#{__LINE__} #{__method__} ZOOM WIDTHxHEIGHT: #{zoom_crop_width}x#{zoom_crop_height}"
          system "convert #{append_filename} -crop #{zoom_crop_width}x#{zoom_crop_height}+#{zoom_crop_width_offset}+#{zoom_crop_height_offset} +repage #{append_filename}"
        end
      rescue => e
        puts "#{__FILE__}:#{__LINE__} #{__method__} #{e}"
      end
    end

    append_filename.sub(@base_path, "")


  end

  def file_in_cache?(cache_dir, mime_type)
    if !File.exists?(cache_dir) then
      Dir.mkdir(cache_dir)
      File.new(cache_dir).chmod(0777)
    end

    show_cache_file(cache_dir, mime_type)
  end

  def show_cache_file(cache_dir, mime_type)
#    cached_file =
=begin
function show_cache_file($cache_dir) {

	$cache_file = $cache_dir . '/' . get_cache_file();

	if (file_exists($cache_file)) {

		$gmdate_mod = gmdate("D, d M Y H:i:s", filemtime($cache_file));

		if(! strstr($gmdate_mod, "GMT")) {
			$gmdate_mod .= " GMT";
		}

		if (isset($_SERVER["HTTP_IF_MODIFIED_SINCE"])) {

			// check for updates
			$if_modified_since = preg_replace("/;.*$/", "", $_SERVER["HTTP_IF_MODIFIED_SINCE"]);

			if ($if_modified_since == $gmdate_mod) {
				header("HTTP/1.1 304 Not Modified");
				exit;
			}

		}

		$fileSize = filesize($cache_file);

		// send headers then display image
		header("Content-Type: image/png");
		header("Accept-Ranges: bytes");
		header("Last-Modified: " . $gmdate_mod);
		header("Content-Length: " . $fileSize);
		header("Cache-Control: max-age=9999, must-revalidate");
		header("Expires: " . $gmdate_mod);

		readfile($cache_file);

		exit;

	}

}
=end
  end

  # tidy up the image source url
  def clean_source(source_uri)

    # remove slash from the start of the string
    if source_uri.starts_with?('/') then
      source_uri = source_uri[1, source_uri.length]
    end

    # remove http/ https/ ftp
    source_uri = source_uri.sub("(^((ht|f)tp(s|):\/\/))", "")
    # remove domain name from the source url
    host = @request.env['SERVER_HOST']
    source_uri = source_uri.sub(host, "")
    host = host.sub("www.", "")
    source_uri = source_uri.sub(host, "")

    # don't allow users the ability to use '../'
    # in order to gain access to files below document root

    # src should be specified relative to document root like:
    # src=images/img.jpg or src=/images/img.jpg
    # not like: src=../images/img.jpg

    source_uri = source_uri.sub("(\.\.+\/)", "")

    # get path to image on file system
    "#{@base_path}/#{source_uri}"

  end

  def mime_src(src)
    `file -Ib #{src}`.gsub(/\n/, "")
  end

end
