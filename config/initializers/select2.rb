module Select2
  module Autocomplete
    def self.as_json(id, text, opts = {})
      {
        id: id,
        text: text,
      }.merge( opts )
    end

  end

end