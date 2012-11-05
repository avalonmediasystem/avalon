group :dropbox do
  guard :hydrant do
    env = ENV['RAILS_ENV'] || 'development'
    ::Guard::UI.info "Loading settings for the #{env} environment"
    opts = YAML::load_file(File.expand_path('./config/hydrant.yml'))[env]
    ::Guard::UI.info "Monitoring #{opts['dropbox']['path']}"
    watch opts['dropbox']['path']
  end
end
