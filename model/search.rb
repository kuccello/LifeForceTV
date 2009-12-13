module Lifeforce
  class SearchResults

    def self.default
      Lifeforce.transaction do
        SearchResults['default']
      end
    end

    def sorted_notes
      []
    end

  end
end
