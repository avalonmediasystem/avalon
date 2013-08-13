module Avalon
  class ControlledVocabulary

    def self.vocabulary
      vocabulary = {}
      path = Rails.root.join(Avalon::Configuration['controlled_vocabulary']['path'])
      if File.file?(path)
        yaml = YAML::load(File.read(path))
        vocabulary = yaml.symbolize_keys if yaml.present?
      end
      vocabulary
    end

    def self.find_by_name( name )
      vocabulary[name.to_sym] || []
    end
  end
end