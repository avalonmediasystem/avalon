# A sample Guardfile
# More info at https://github.com/guard/guard#readme

group :dropbox do

	guard :hydrant do
		env = ENV['RAILS_ENV'] || 'development'
		opts = YAML.load(File.read(File.expand_path('../config/hydrant.yml',__FILE__)))[env]
		::Guard::UI.info "Starting dropbox on #{opts['dropbox']['path']}"
	  watch (opts['dropbox']['path'])
	end
	
end