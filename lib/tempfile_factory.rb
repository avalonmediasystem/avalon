# Middleware to override the default Rack::Multipart tempfile factory: 
# https://www.rubydoc.info/gems/rack/Rack/Multipart/Parser#TEMPFILE_FACTORY-constant
class TempfileFactory
  def initialize(app)
    @app = app
    return unless Settings.tempfile.present?
    if Settings.tempfile&.location.present? && File.directory?(Settings.tempfile&.location) && File.writable?(Settings.tempfile&.location)
      @tempfile_location = Settings.tempfile.location
    else
      logger = ActiveSupport::TaggedLogging.new(Logger.new(File.join(Rails.root, 'log', "#{Rails.env}.log")))
      logger.tagged('Rack::Multipart', 'Tempfile').warn "#{Settings.tempfile.location} is not a diretory or not writable. Falling back to #{Dir.tmpdir}."
    end
  end

  def call(env)
    if @tempfile_location
      env["rack.multipart.tempfile_factory"] = lambda { |filename, content_type| 
        extension = ::File.extname(filename.gsub("\0", '%00'))[0, 129]
        Tempfile.new(["RackMultipart", extension], @tempfile_location)
      }
    end

    @app.call(env)
  end
end