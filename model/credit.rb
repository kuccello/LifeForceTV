require 'digest/sha1'
module Lifeforce
  class Credit
    
    def self.get_by_pid(pid)
      ad = nil
      Lifeforce.transaction do
        ad = Credit[pid]
      end
      ad
    end

    def is_cast?
      self.type_of == 'cast'
    end

    def update_data(params)
      Lifeforce.transaction do
        self.name = params['name']
        self.role = params['role']
        self.image = params['image']
        self.desc = params['desc']
        self.zorder = params['zorder']
        self.type_of = params['type_of']
      end
    end

    def self.make_new_epidose_credit(episode,params)
      credit = nil
      Lifeforce.transaction do
        credit = episode.new_credit(Digest::SHA1.hexdigest("#{episode.name}#{Time.new.to_s}"))
      end
      credit.update_data(params) if credit
      credit
    end
    def self.make_new_show_credit(show,params)
      credit = nil
      Lifeforce.transaction do
        credit = show.new_credit(Digest::SHA1.hexdigest("#{show.name}#{Time.new.to_s}"))
      end
      credit.update_data(params) if credit
      credit
    end

    def self.remove_credit_from_episode(episode,credit)
      Lifeforce.transaction do
        episode.remove_credit(credit) if credit
      end
    end
    def self.remove_credit_from_show(show,credit)
      Lifeforce.transaction do
        show.remove_credit(credit) if credit
      end
    end

  end
end
