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
class IndexMetadataMediaObjectComponent < Blacklight::DocumentMetadataComponent
  # @param fields [Enumerable<Blacklight::FieldPresenter>] Document field presenters
  # rubocop:disable Metrics/ParameterLists
  def initialize(**kwargs)
    super
    @classes += %w[col-md-12 col-lg-8]
    @field_layout ||= MetadataFieldLayoutComponent
  end

  def before_render
    return unless fields

    @fields.each do |field|
      @document = field.document
      with_field(component: field.component, field: field, show: @show, view_type: @view_type, layout: @field_layout)
    end
  end
end
