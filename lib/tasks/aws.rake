# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

namespace :avalon do
  namespace :aws do
    task create_presets: :environment do
      require 'aws-sdk'

      et = Avalon::ElasticTranscoder.instance
      templates = et.read_templates(Rails.root.join(Settings.encoding.presets_path))
      templates.each do |template|
        unless et.find_preset_by_name(template[:name]).present?
          preset = et.create_preset(template)
          Rails.logger.info "#{template[:name]}: #{preset.id}"
        end
      end
    end
  end
end
