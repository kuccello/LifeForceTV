module Lifeforce
  class MostRecentEpisodes

#    def self.normalize
#      Lifeforce.transaction do
#        Lifeforce.root.show.each do |s|
#          s.episode.each do |e|
#            Lifeforce.root. unless Lifeforce.root.episode[e.pid]
#          end
#        end
#      end
#    end

    def self.build(ep_arr)
      Lifeforce.transaction do
        Lifeforce.root.remove_most_recent_episodes(Lifeforce.root.most_recent_episodes.first)
      end

      Lifeforce.transaction do
        mre = Lifeforce.root.most_recent_episodes["default"]
        unless mre
          mre = Lifeforce.root.new_most_recent_episodes("default")
        end

        ep_arr.each_with_index do |e,idx|
          er = mre.ep_ref[idx]
          unless er
            er = mre.new_ep_ref("#{Time.new.to_i}")
          end
          er.episode = e.pid
          er.show = e.show
        end
      end
#      puts "#{__FILE__}:#{__LINE__} #{__method__} \n\n #{Lifeforce.root.most_recent_episodes.first.pp_xml}"
    end

    def self.get
      res = []
      Lifeforce.transaction do
        mre = Lifeforce.root.most_recent_episodes["default"]
        unless mre
          mre = Lifeforce.root.new_most_recent_episodes("default")
        end

        res = mre.ep_ref
      end
      eps = []
      res.each do |r|
#        puts "#{__FILE__}:#{__LINE__} #{__method__} #{r.pp_xml}"
        show =  Lifeforce.root.show[r.show]
        if show then
          eps << show.episode[r.episode]
        end
      end
      eps
    end
  end
end
