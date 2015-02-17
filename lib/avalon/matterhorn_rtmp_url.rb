# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

require 'uri'

module Avalon
  class MatterhornRtmpUrl < Struct.new(:application, :prefix, :media_id, :stream_id, :filename, :extension)

    REGEX = %r{^
      /(?<application>.+)        # application (avalon)
      /(?:(?<prefix>.+):)?       # prefix      (mp4:)
      (?<media_id>[^\/]+)        # media_id    (98285a5b-603a-4a14-acc0-20e37a3514bb)
      /(?<stream_id>[^\/]+)      # stream_id   (b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3)
      /(?<filename>.+?)          # filename    (MVI_0057)
      (?:\.(?<extension>.+))?$   # extension   (mp4)
    }x

    def initialize(hash)
      super(*members.map {|member| hash[member]})
    end

    def self.parse(url_string)
      # Example input: /avalon/mp4:98285a5b-603a-4a14-acc0-20e37a3514bb/b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3/MVI_0057.mp4

      uri = URI.parse(url_string)
      match_data = REGEX.match(uri.path)
      MatterhornRtmpUrl.new match_data    
    end

    alias_method :'_binding', :'binding'
    def binding
      _binding
    end

    def to_path
      File.join(media_id, stream_id, "#{filename}.#{extension||prefix}")
    end
  end
end
