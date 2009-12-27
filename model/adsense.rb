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
        self.content = params['code']
      end
    end
  end
end
