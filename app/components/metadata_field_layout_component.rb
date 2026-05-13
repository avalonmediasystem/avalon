# Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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
class MetadataFieldLayoutComponent < Blacklight::Component
  with_collection_parameter :field
  renders_one :label
  renders_many :values, (lambda do |value: nil, &block|
    if @value_tag.nil?
      block&.call || value
    elsif block
      content_tag @value_tag, class: "#{@value_class} blacklight-#{@key}", data: { testid: "browse-value-#{@key}" }, &block
    else
      content_tag @value_tag, value, class: "#{@value_class} blacklight-#{@key}", data: { testid: "browse-value-#{@key}" }
    end
  end)

  # @param field [Blacklight::FieldPresenter]
  def initialize(field:, value_tag: 'dd', label_class: 'col-md-3', value_class: 'col-md-9')
    @field = field
    @key = @field.key.parameterize
    @label_class = label_class
    @value_tag = value_tag
    @value_class = value_class
  end
end
