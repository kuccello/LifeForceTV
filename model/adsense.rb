require 'digest/sha1'
module Lifeforce
  class AdSense
    def self.get_by_pid(pid)
      ad = nil
      Lifeforce.transaction do
        ad = AdSense[pid]
      end
      ad
    end

    def self.make_ad
      ad = nil
      Lifeforce.transaction do
        ad = Lifeforce.root.new_ad_sense(Digest::SHA1.hexdigest(Time.new.to_s))
        ad.title = "Untitled"
        ad.content = ""
      end
      ad
    end

    def update_data(params)
      Lifeforce.transaction do
        self.title = params['title']
        self.content = "<![CDATA[#{params['code']}]]>"
        puts "#{__FILE__}:#{__LINE__} #{__method__} \n\n#{self.content}\n\n"
      end
    end

    def self.delete_this_ad(ad)
      Lifeforce.transaction do
        Lifeforce.root.remove_ad_sense(ad) if ad
      end
    end

    def self.get_ad_by_label(title)
      ad = nil
      Lifeforce.transaction do
        Lifeforce.root.ad_sense.each do |adx|
          ad = adx if adx.title == title
        end
      end
      ad
    end

    def self.ad_content(ad)
      ad.content.sub("<![CDATA[",'').sub("]]>",'')
    end

    def self.get_layout_ad
      self_get_ad_by_label = self.get_ad_by_label("layout")
      return self.ad_content( self_get_ad_by_label) if self_get_ad_by_label
      ""
    end
  end
end
