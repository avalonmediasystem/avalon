# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

class SpeedyAF::Proxy::IndexedFile < SpeedyAF::Base
  # If necessary, decode binary content that is base 64 encoded
  def content
    # Reify if content exists but isn't stored in the index
    if !empty? && attrs[:content].blank?
      ActiveFedora::Base.logger.warn("Reifying #{model} because content not indexed")
      return real_object.content
    end
    binary_content? ? Base64.decode64(attrs[:content]) : attrs[:content]
  end

  def persisted?
    id.present?
  end

  def has_content?
    attrs[:content].present?
  end

  def binary_content?
    has_content? && mime_type !~ /(^text\/)|([\/\+]xml$)/
  end
end
