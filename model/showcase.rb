module Lifeforce
  class Showcase

    def add_episode(episode_pid)

      o = sorted.size
      Lifeforce.transaction do

        se = self.new_showcase_episode("#{Time.new.to_i}")
        se.episode = episode_pid
        se.order = o
        se.status = ShowcaseEpisode::STATUS_ACTIVE

      end
    end

    def remove_episode(episode_pid)
      sorted.each do |ep_ref|
        if ep_ref.episode == episode_pid
          Lifeforce.transaction do
            self.remove_showcase_episode(ep_ref.id)
          end
        end
      end
      reorder
    end

    def reorder
      s = sorted
      Lifeforce.transaction do
        for i in 0..(s.size-1) do
          s[i].order = i
        end
      end
    end

    def move_episode_up(ep_id)
      ep_ref = self.showcase_episode[ep_id]
      if ep_ref
        new_idx = ep_ref.order.to_i - 1
        if new_idx > -1

          second_ep = sorted[new_idx]

          swap(ep_id, second_ep.id)
        end
      end
    end

    def move_episode_down(ep_id)
      ep_ref = self.showcase_episode[ep_id]
      if ep_ref
        new_idx = ep_ref.order.to_i + 1
        if new_idx < sorted.size

          second_ep = sorted[new_idx]

          swap(ep_id, second_ep.id)
        end
      end
    end

    def swap(ep_id_a, ep_id_b)
      Lifeforce.transaction do
        ep_ref_a = self.showcase_episode[ep_id_a]
        ep_ref_b = self.showcase_episode[ep_id_b]
        ep_ref_a.order, ep_ref_b.order = ep_ref_b.order, ep_ref_a.order
      end
    end

    def change_order(ep_id, index = -1)
      if index > -1

        showcase_episodes = sorted
        showcase_episode_count = showcase_episodes.size - 1

        if index < showcase_episode_count

          ep_ref = self.showcase_episode[ep_id]
          if ep_ref

            cur_index = ep_ref.order.to_i

            if cur_index != index

              # we are moving up a bunch
              if cur_index > index
                for r in index..cur_index do
                  move_episode_up(ep_id)
                end
                # we are moving down a bunch
              else
                for r in index..cur_index do
                  move_episode_down(ep_id)
                end
              end
            end
          end
        end
      end
    end

    def sorted
      self.showcase_episode.sort { |a, b| a.order.to_i <=> b.order.to_i }
    end

    def episodes
      episodes = []
      sea = self.showcase_episode.sort { |a, b| a.order.to_i <=> b.order.to_i }
      Lifeforce.transaction do
        sea.each do |ep_ref|
          if ep_ref.status == ShowcaseEpisode::STATUS_ACTIVE
            ep = Episode[ep_ref.episode]
            if ep.status == Episode::STATUS_LIVE && ep.is_released?
              episodes << ep
            end
          end
        end
      end
      episodes
    end

    def contains_episode?(episode)
      sorted.each do |ep_ref|
        return true if ep_ref.episode == episode.pid
      end
      return false
    end

    def self.default
      Lifeforce.transaction do
        Showcase['default']
      end
    end

    def self.create_default_showcase()
      Lifeforce.transaction do
        Lifeforce.root.new_showcase('default')
      end
    end

    # ===================
    # Shows

    def add_show(show_pid)

      o = sorted.size
      Lifeforce.transaction do

        sh = self.new_showcase_show("#{Time.new.to_i}")
        sh.show = show_pid
        sh.order = o
        sh.status = ShowcaseShow::STATUS_ACTIVE

      end
    end

    def remove_show(show_pid)
      sorted_shows.each do |show_ref|
        if show_ref.show == show_pid
          Lifeforce.transaction do
            self.remove_showcase_show(show_ref.id)
          end
        end
      end
      reorder_shows
    end

    def reorder_shows
      s = sorted_shows
      Lifeforce.transaction do
        for i in 0..(s.size-1) do
          s[i].order = i
        end
      end
    end

    def move_show_up(show_id)
      show_ref = self.showcase_show[show_id]
      if show_ref
        new_idx = show_ref.order.to_i - 1
        if new_idx > -1

          second_show = sorted_shows[new_idx]

          swap_show(show_id, second_show.id)
        end
      end
    end

    def move_show_down(show_id)
      show_ref = self.showcase_show[show_id]
      if show_ref
        new_idx = show_ref.order.to_i + 1
        if new_idx < sorted_shows.size

          second_show = sorted_shows[new_idx]

          swap_show(show_id, second_show.id)
        end
      end
    end

    def swap_show(show_id_a, show_id_b)
      Lifeforce.transaction do
        show_ref_a = self.showcase_show[show_id_a]
        show_ref_b = self.showcase_show[show_id_b]
        show_ref_a.order, show_ref_b.order = show_ref_b.order, show_ref_a.order
      end
    end

    def change_show_order(show_id, index = -1)
      if index > -1

        showcase_show = sorted_shows
        showcase_show_count = showcase_show.size - 1

        if index < showcase_show_count

          show_ref = self.showcase_show[show_id]
          if show_ref

            cur_index = show_ref.order.to_i

            if cur_index != index

              # we are moving up a bunch
              if cur_index > index
                for r in index..cur_index do
                  move_show_up(show_id)
                end
                # we are moving down a bunch
              else
                for r in index..cur_index do
                  move_show_down(show_id)
                end
              end
            end
          end
        end
      end
    end

    def sorted_shows
      self.showcase_show.sort { |a, b| a.order.to_i <=> b.order.to_i }
    end

    def shows
      shows = []
      sea = self.showcase_show.sort { |a, b| a.order.to_i <=> b.order.to_i }
      Lifeforce.transaction do
        sea.each do |show_ref|
          if show_ref.status == ShowcaseShow::STATUS_ACTIVE
            show = Show[show_ref.show]
            if show.status == Show::STATUS_LIVE && show.is_released?
              shows << show_ref
            end
          end
        end
      end
      shows
    end

    def contains_show?(show)
      sorted_shows.each do |show_ref|
        return true if show_ref.show == show.pid
      end
      return false
    end

    # ===================
    # Notes

    def add_note(note_pid)

      o = sorted.size
      Lifeforce.transaction do

        sh = self.new_showcase_note("#{Time.new.to_i}")
        sh.note = note_pid
        sh.order = o
        sh.status = 'active'

      end
    end

    def remove_note(note_pid)
      sorted_notes.each do |note_ref|
        if note_ref.note == note_pid
          Lifeforce.transaction do
            self.remove_showcase_note(note_ref.id)
          end
        end
      end
      reorder_notes
    end

    def reorder_notes
      s = sorted_notes
      Lifeforce.transaction do
        for i in 0..(s.size-1) do
          s[i].order = i
        end
      end
    end

    def move_note_up(note_id)
      note_ref = self.showcase_note[note_id]
      if note_ref
        new_idx = note_ref.order.to_i - 1
        if new_idx > -1

          second_note = sorted_notes[new_idx]

          swap_note(note_id, second_note.id)
        end
      end
    end

    def move_note_down(note_id)
      note_ref = self.showcase_note[note_id]
      if note_ref
        new_idx = note_ref.order.to_i + 1
        if new_idx < sorted_notes.size

          second_note = sorted_note[new_idx]

          swap_note(note_id, second_note.id)
        end
      end
    end

    def swap_note(note_id_a, note_id_b)
      Lifeforce.transaction do
        note_ref_a = self.showcase_note[note_id_a]
        note_ref_b = self.showcase_note[note_id_b]
        note_ref_a.order, note_ref_b.order = note_ref_b.order, note_ref_a.order
      end
    end

    def change_note_order(note_id, index = -1)
      if index > -1

        showcase_notes = sorted_notes
        showcase_note_count = showcase_notes.size - 1

        if index < showcase_note_count

          note_ref = self.showcase_note[note_id]
          if note_ref

            cur_index = note_ref.order.to_i

            if cur_index != index

              # we are moving up a bunch
              if cur_index > index
                for r in index..cur_index do
                  move_note_up(note_id)
                end
                # we are moving down a bunch
              else
                for r in index..cur_index do
                  move_note_down(note_id)
                end
              end
            end
          end
        end
      end
    end

    def sorted_notes
      self.showcase_note.sort { |a, b| a.order.to_i <=> b.order.to_i }
    end

    def notes
      notes = []
      sea = self.showcase_note.sort { |a, b| a.order.to_i <=> b.order.to_i }
      Lifeforce.transaction do
        sea.each do |note_ref|
          if note_ref.status == ShowcaseNote::STATUS_ACTIVE
            note = Note[note_ref.note]
            if note.status == Note::STATUS_LIVE && note.is_released?
              notes << note_ref
            end
          end
        end
      end
      notes
    end

    def contains_note?(note)
      sorted_notes.each do |note_ref|
        return true if note_ref.note == note.pid
      end
      return false
    end

  end

  class ShowcaseEpisode
    STATUS_ACTIVE = 'active'
    STATUS_INACTIVE = 'inactive'

    def ep
      Episode.get_by_pid(self.episode)
    end
  end

  class ShowcaseShow
    STATUS_ACTIVE = 'active'
    STATUS_INACTIVE = 'inactive'

    def s
      Show.get_by_pid(self.show)
    end
  end

  class ShowcaseNote
    STATUS_ACTIVE = 'active'
    STATUS_INACTIVE = 'inactive'

    def n
      Note.get_by_pid(self.note)
    end
  end

end
