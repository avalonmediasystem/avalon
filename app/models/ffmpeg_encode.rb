# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

class FfmpegEncode < WatchedEncode
  self.engine_adapter = :ffmpeg

  before_create prepend: true do |encode|
    encode.options.merge!(outputs: ffmpeg_outputs(encode.options))
  end

  private

    def presets
      @presets ||= YAML.load_file Rails.root.join(Settings.encoding.presets_path)
    end

    def ffmpeg_outputs(options)
      presets[options[:preset]] || []
    end
end
