module Hydrant
  Configuration = YAML::load(File.read(Rails.root.join('config', 'hydrant.yml')))
end
