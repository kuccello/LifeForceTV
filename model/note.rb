require 'maruku'

module Lifeforce
  class Note

    STATUS_PENDING = "pending"
    STATUS_LIVE = "live"
    STATUS_DELETED = "deleted"

    def Note.get_by_pid(pid)
      note = nil
      Lifeforce.transaction do

        note = Note[pid]

      end
      note
    end

    def Note.all
      notes = []
      Lifeforce.transaction do
        notes = Lifeforce.root.note
      end
      notes
    end

    def Note.make_new_note()
      note = nil
      Lifeforce.transaction do
        note = Lifeforce.root.new_note("note-#{Time.new.to_i}")
        note.title = "Unitled"
        note.status = STATUS_PENDING
        note.content = ""
      end
      note
    end


    def Note.notes_by_filter(status)
      notes = []
      Note.all.each do |note|
        notes << note if note.status == status || note.status == nil || note.status.strip.length == 0
      end
      notes
    end

    def Note.live_notes
      notes_by_filter(STATUS_LIVE)
    end

    def Note.pending_notes
      notes_by_filter(STATUS_PENDING)
    end

    def Note.deleted_notes
      notes_by_filter(STATUS_DELETED)
    end

    def update(params)

      note_title = params[:note_title]
      note_status = params[:note_status]
      note_body = params[:note_body]

      Lifeforce.transaction do
        self.title = note_title
        self.content = note_body
        self.status = note_status
      end

      note_showcase_rm = params[:note_showcase_remove]
      note_showcase_add = params[:note_showcase_add]

      if note_showcase_rm then
        # remove from the showcase
        Showcase.default.remove_note(self.pid)
      end

      if note_showcase_add then
        # add to the showcase
        Showcase.default.add_note(self.pid)
      end

      true
    end

    def html_content
      Maruku.new(self.content).to_html      
    end
=begin
<note pid=""
        title=""
        status="active|inactive"><![CDATA[Content - MARKDOWN goes here]]></note>
=end

  end
end
