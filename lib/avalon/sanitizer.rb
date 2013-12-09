module Avalon
  module Sanitizer
    def self.sanitize(name, opts = { whitelist: 'abcdefghijklmnopqrstuvwxyz0123459_-' })
      name.split('').map{|char| 
        if char == ' '
          '_'
        elsif opts[:whitelist].include?(char) || opts[:whitelist].upcase.include?(char) 
          char
        end
      }.join
    end
  end
end