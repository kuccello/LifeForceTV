module Lifeforce
  class Genera


    def Genera.get_by_pid(pid)
      g = nil
      Lifeforce.transaction do

        g = Genera[pid] if pid

      end
      g
    end

    def Genera.all
      r = []
      Lifeforce.transaction do
        r = Lifeforce.root.genera
      end
      r
    end

    def Genera.get_by_name(name)
      Genera.each do |g|
        return g if g.name.downcase == name.downcase
      end
      nil
    end

    def Genera.remove_from_system(genera)
      Lifeforce.transaction do

        Lifeforce.root.show.each do |show|
          show.remove_genera(genera)
          show.episode.each do |ep|
            ep.remove_genera(genera)
          end
          Lifeforce.root.remove_genera(genera)
        end

        # remove the genera
      end
    end

    def Genera.all
      Lifeforce.transaction do
        Lifeforce.root.genera
      end
    end

    def Genera.make_new_genera(name)
      genera = get_by_pid(Lifeforce.pid_from_string(name.downcase))
      unless genera
        Lifeforce.transaction do

          genera = Lifeforce.root.new_genera(Lifeforce.pid_from_string(name.downcase))

          genera.name = name

        end
      end
      genera
    end


    def add_show(show)
      unless has_show?(show)
        Lifeforce.transaction do
          self.new_show_ref(Lifeforce.pid_from_string("show-#{show.pid}"))
        end
      end
    end

    def remove_show(show)
      if self.has_show?(show) then
        Lifeforce.transaction do
          self.remove_show_ref(show.pid)
        end
      end
    end

    def add_episode(episode)
      unless has_episode?(episode)
        Lifeforce.transaction do
          self.new_episode_ref(Lifeforce.pid_from_string("ep-#{episode.pid}"))
        end
      end
    end

    def remove_episode(episode)
      if self.has_episode?(episode)
        Lifeforce.transaction do
          self.remove_episode_ref(episode.pid)
        end
      end
    end

    def has_show?(show)
      self.show_ref.each do |s|
        return true if s.show == show.pid
      end
      false
    end

    def has_episode?(episode)
      self.episode_ref.each do |e|
        return true if e.episode == episode.pid
      end
      false
    end
  end

  
end
