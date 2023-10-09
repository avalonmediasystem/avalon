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

# An extension of the ActiveAnnotations gem to include Avalon specific information in the Annotation
# Sets defaults for the annotation using information from the master_file and includes solrization of the annotation
# @since 5.0.1
class AvalonAnnotation < ActiveAnnotations::Annotation

  alias_method :title, :label
  alias_method :title=, :label=

  validates :master_file, :title, :start_time, presence: true
  validates :start_time, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: Proc.new { |a| a.max_time }, 
    message: "must be between 0 and end of section"
  }

  after_initialize do
    selector_default!
    title_default!
  end

  # This function determines the max time for a masterfile and its derivatives
  # Used for determining the maximum possible end time for an annotation
  # @return [float] the largest end time or -1 if no durations present
  def max_time
    max = -1
    max = master_file.duration.to_f if master_file.present? && master_file.duration.present?
    if master_file.present?
      master_file.derivatives.each do |derivative|
        max = derivative.duration.to_f if derivative.present? && derivative.duration.present? && derivative.duration.to_f > max
      end
    end
    max
  end

  # Sets the default selector to a start time of 0 and an end time of the master file length
  def selector_default!
    self.start_time = 0 if self.start_time.nil?
  end

  # Set the default title to be the label of the master_file
  def title_default!
    self.title = master_file.embed_title if self.title.nil? && master_file.present?
  end

  # Sets the class variable @master_file by finding the master referenced in the source uri
  def master_file
    @master_file ||= SpeedyAF::Proxy::MasterFile.find(CGI::unescape(self.source.split('/').last)) if self.source
  end

  def master_file=(value)
    @master_file = value
    self.source = @master_file
    @master_file
  end

  # Calcuates the mediafragment_uri based on either the internal fragment value or start and end times
  # @return [String] the uri with time bounding
  def mediafragment_uri
    "#{master_file&.rdf_uri}?#{internal.fragment_value.object}"
  rescue
    "#{master_file&.rdf_uri}?t=#{start_time},#{end_time}"
  end

end
