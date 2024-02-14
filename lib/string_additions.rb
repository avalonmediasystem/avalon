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

module StringAdditions
  ZERO_WIDTH_CHARS = ["\u200B", "\u200C", "\u200D", "\uFEFF", "\u2060"].freeze

  # Removes zero-width character from beginning and end of string
  def remove_zero_width_chars
    gsub(/^[#{String::ZERO_WIDTH_CHARS.join}]/, '').gsub(/[#{String::ZERO_WIDTH_CHARS.join}]$/, '')
  end
end
String.prepend(StringAdditions)
