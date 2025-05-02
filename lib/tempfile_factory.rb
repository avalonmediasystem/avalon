# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

# Middleware to override the default Rack::Multipart tempfile factory: 
# https://www.rubydoc.info/gems/rack/Rack/Multipart/Parser#TEMPFILE_FACTORY-constant
class TempfileFactory
  def initialize(app)
    @app = app
    return unless Settings.tempfile.present?
    if Settings.tempfile&.location.present? && File.directory?(Settings.tempfile&.location) && File.writable?(Settings.tempfile&.location)
      @tempfile_location = Settings.tempfile.location
    else
      logger.warn("[Rack::Multipart] [Tempfile] #{Settings.tempfile.location} is not a diretory or not writable. Falling back to #{Dir.tmpdir}.")
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

  private

  def logger
    @logger ||= Logger.new(File.join(Rails.root, 'log', "#{Rails.env}.log"))
  end
end
