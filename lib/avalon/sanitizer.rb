module Avalon
  module Sanitizer
    def self.sanitize(name, translations=['\\/ &:.','______'])
      name.tr *translations
    end
  end
end