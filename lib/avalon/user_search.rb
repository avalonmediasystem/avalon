module Avalon
  class UserSearch
    def initialize( args = {} )
      
    end

    def self.format_autocomplete_entry(args = {})
      text = "#{args[:full_name]}"
      text += "(#{args[:email]})" if args[:email]
      text += "#{args[:uid]}" if  ! args[:full_name] && ! args[:email]

      {
        id: args[:uid],
        text: text
      }
    end

    def autocomplete(query)
      [self.class.format_autocomplete_entry({ uid: query, full_name: query, email: query })]
    end

    def self.find_by_uid( uid )
      {
        uid: uid
      }
    end

    def find_by_uid( uid )
      {
        uid: uid
      }
    end
  end
end