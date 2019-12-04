# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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
# frozen_string_literal: true
class SpeedyAF::Proxy::MasterFile < SpeedyAF::Base
  def encoder_class
    find_encoder_class(encoder_classname) || find_encoder_class(workflow_name.to_s.classify) || find_encoder_class((Settings.encoding.engine_adapter + "_encode").classify) || MasterFile.default_encoder_class || WatchedEncode
  end

  def find_encoder_class(klass_name)
    ActiveEncode::Base.descendants.find { |c| c.name == klass_name }
  end
  
  def display_title
    mf_title = structuralMetadata.section_title if has_structuralMetadata?
    mf_title ||= title if title.present?
    mf_title ||= file_location.split("/").last if file_location.present? && (media_object.master_file_ids.size > 1)
    mf_title.blank? ? nil : mf_title
  end
end
