module UserSearch
  class Local
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

    def self.autocomplete(query)
      users = User.where("username LIKE ?", "#{query}%")
      users.map{ |u| self.format_autocomplete_entry( uid: u.username, full_name: u.username, email: u.username ) }
    end

    def self.find_by_uid( username )
      user = User.find_by_username(username)
      return self.as_json(user) unless user.nil?
    end

    def self.as_json( user )
      {
        uid: user.username,
        username: user.username,
        email: user.email,
        first_name: "",
        last_name: "",
        full_name: user.full_name,
        indirect_name: "" 
      }
    end
  end
end
