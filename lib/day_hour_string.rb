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

module DayHourString
  def to_day_hour_s
    d, h = (self / 3600).divmod(24)

    day_string = d.positive? ? d.to_s + ' day'.pluralize(d) : nil
    hour_string = h.positive? ? h.to_s + ' hour'.pluralize(h) : nil

    if day_string.nil?
      hour_string
    elsif hour_string.nil?
      day_string
    else
      day_string + ' ' + hour_string
    end
  end
end
ActiveSupport::Duration.prepend(DayHourString)
