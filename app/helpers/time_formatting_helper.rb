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

module TimeFormattingHelper
  # We are converting FFprobe's duration output to milliseconds for
  # uniformity with existing metadata and consequently leaving these
  # conversion methods in place for now.
  def milliseconds_to_formatted_time(milliseconds, include_fractions = true)
    total_seconds = milliseconds / 1000
    hours = total_seconds / (60 * 60)
    minutes = (total_seconds / 60) % 60
    seconds = total_seconds % 60
    fractional_seconds = milliseconds.to_s[-3, 3].to_i
    fractional_seconds = (include_fractions && fractional_seconds.positive? ? ".#{fractional_seconds}" : '')

    output = ''
    if hours > 0
      output += "#{hours}:"
    end

    output += "#{minutes.to_s.rjust(2,'0')}:#{seconds.to_s.rjust(2,'0')}#{fractional_seconds}"
    output
  end

  # display millisecond times in HH:MM:SS.sss format
  # @param [Float] milliseconds the time to convert
  # @return [String] time in HH:MM:SS.sss
  def pretty_time(milliseconds)
    milliseconds = Float(milliseconds).to_int # will raise TypeError or ArgumentError if unparsable as a Float
    return "00:00:00.000" if milliseconds <= 0

    total_seconds = milliseconds / 1000.0
    hours = (total_seconds / (60 * 60)).to_i.to_s.rjust(2, "0")
    minutes = ((total_seconds / 60) % 60).to_i.to_s.rjust(2, "0")
    seconds = (total_seconds % 60).to_i.to_s.rjust(2, "0")
    frac_seconds = (milliseconds % 1000).to_s.rjust(3, "0")[0..2]
    hours + ":" + minutes + ":" + seconds + "." + frac_seconds
  end
end
