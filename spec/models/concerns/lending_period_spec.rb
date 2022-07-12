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

describe LendingPeriod do

  before(:all) do
    class Foo < ActiveFedora::Base
      include LendingPeriod

      attr_accessor :collection_id
    end
  end

  after(:all) { Object.send(:remove_const, :Foo) }

  subject { Foo.new }

  let(:co) { FactoryBot.create(:collection) }

  before { subject.collection_id = co.id }

  it 'defines lending_period' do
    expect(subject.attributes).to include('lending_period')
  end

  describe 'set_lending_period' do
    context 'a custom lending period has not been set' do
      it 'is equal to the default period in the settings.yml' do
        subject.set_lending_period
        expect(subject.lending_period).to eq ActiveSupport::Duration.parse(Settings.controlled_digital_lending.default_lending_period).to_i
      end
    end
    context 'a plain text custom lending period has been set' do
      let(:media_object) { FactoryBot.create(:media_object, lending_period: "1 day") }
      let(:complex_date) { FactoryBot.create(:collection, lending_period: "6 days 4 hours")}
      it 'is equal to the custom lending period measured in seconds' do
        media_object.set_lending_period
        expect(media_object.lending_period).to eq 86400
      end
      it 'accepts strings containing day and hour' do
        expect { complex_date.set_lending_period }.not_to raise_error
      end
    end
    context 'an ISO8601 duration format custom lending period has been set' do
      let(:media_object) { FactoryBot.create(:collection, lending_period: "P1D") }
      let(:year_month) { FactoryBot.create(:media_object, lending_period: "P1Y2M") }
      let(:day_hr_min_sec) { FactoryBot.create(:collection, lending_period: "P4DT6H3M30S")}
      let(:sec) { FactoryBot.create(:media_object, lending_period: "PT3650.015S")}
      it 'is equal to the custom lending period measured in seconds' do
        media_object.set_lending_period
        expect(media_object.lending_period).to eq 86400
      end
      it 'accepts any ISO8601 duration' do
        expect { year_month.set_lending_period }.not_to raise_error
        expect { day_hr_min_sec.set_lending_period }.not_to raise_error
        expect { sec.set_lending_period }.not_to raise_error
      end
    end
  end
end
