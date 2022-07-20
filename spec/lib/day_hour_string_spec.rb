# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

require 'rails_helper'

describe 'HumanReadableDuration' do
  describe 'to_human_readable_s' do
    context 'when lending period is measured in days' do
      let(:media_object) { instance_double("MediaObject", lending_period: 172800) }

      it 'returns the lending period as a human readable string' do
        expect(ActiveSupport::Duration.build(media_object.lending_period).to_day_hour_s).to eq("2 days")
      end
    end
    context 'when lending period is measured in hours' do
      let(:collection) { instance_double("Admin::Collection", default_lending_period: 7200) }

      it 'returns the lending period as a human readable string' do
        expect(ActiveSupport::Duration.build(collection.default_lending_period).to_day_hour_s).to eq("2 hours")
      end
    end
    context 'when lending period is measured in days and hours' do
      let(:media_object) { instance_double("MediaObject", lending_period: 129600) }

      it 'returns the lending period as a human readable string' do
        expect(ActiveSupport::Duration.build(media_object.lending_period).to_day_hour_s).to eq("1 day 12 hours")
      end
    end
    context 'when lending period includes 1 day and/or 1 hour' do
      let(:day) { instance_double("MediaObject", lending_period: 86400) }
      let(:hour) { instance_double("MediaObject", lending_period: 3600) }
      let(:day_hour) { instance_double("Admin::Collection", default_lending_period: 90000) }

      it 'returns the lending period as a human readable string with singular day and/or hour' do
        expect(ActiveSupport::Duration.build(day.lending_period).to_day_hour_s).to eq("1 day")
        expect(ActiveSupport::Duration.build(hour.lending_period).to_day_hour_s).to eq("1 hour")
        expect(ActiveSupport::Duration.build(day_hour.default_lending_period).to_day_hour_s).to eq("1 day 1 hour")
      end
    end
  end
end
