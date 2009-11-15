#!/usr/bin/env ruby -w -I..

require 'rubygems'

if $0 == __FILE__ then

    class File
      def File.sjoin(*args)
        File.join(args.select{ | o | o })
      end
    end

    require 'xampl-generator'

    include XamplGenerator
    include Xampl

    Xampl.transaction("setup", :in_memory) do
      directory = File.sjoin(".", "generated_model")

      the_options = Xampl.make(Options) { | options |
        options.new_index_attribute("pid").persisted = true
        options.new_index_attribute("id")
        options.resolve("http://www.soldierofcode.com/lifeforce", "Lifeforce", 'lifeforce')
      }

      filenames = Dir.glob("./xml/**/*.xml")

      generator = Generator.new
      generator.go(:options => the_options,
                   :filenames => filenames,
                   :directory => directory)

      #puts generator.print_elements("./generated-elements.xml")

      file_name = File.join(File.dirname(__FILE__), "generated_model/Lifeforce.rb")
      text = File.read(file_name)

      fixed = text.gsub(/include Lifeforce::/, "include ")

      File.open(file_name, "w") {|file| file.puts fixed}

      $LOAD_PATH.unshift(directory)

      exit!
    end

end
