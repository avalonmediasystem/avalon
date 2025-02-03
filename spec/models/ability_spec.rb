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

require 'rails_helper'

describe Ability, type: :model do
  describe 'non-logged in users' do
    it 'only belongs to the public group' do
      expect(Ability.new(nil).user_groups).to eq ["public"]
    end
  end

  describe 'repository read-only mode' do
    # Next line is let! to ensure that it runs before the before block which would stop the object from being created
    let!(:media_object) { FactoryBot.create(:media_object) }
    let(:media_object_proxy) { SpeedyAF::Base.find(media_object.id) }
    let(:collection) { media_object.collection }
    let(:collection_proxy) { SpeedyAF::Base.find(collection.id) }
    let(:admin) { FactoryBot.create(:administrator) }
    let(:session) { {} }
    subject(:admin_ability) { Ability.new(admin, session) }

    before { allow(Settings).to receive(:repository_read_only_mode).and_return(read_only) }

    context 'with read-only enabled' do
      let(:read_only) { true }

      it 'has read-only abilities' do
        expect(subject.can?(:manage, :all)).to eq true
        expect(subject.can?(:manage, MediaObject)).to eq true
        expect(subject.can?(:discover_everything, MediaObject)).to eq true

        expect(subject.can?(:read, media_object)).to eq true
        expect(subject.can?(:read, media_object_proxy)).to eq true
        expect(subject.can?(:read, collection)).to eq true
        expect(subject.can?(:read, collection_proxy)).to eq true

        expect(subject.can?(:create, MediaObject)).to eq false
        expect(subject.can?(:read, MediaObject)).to eq true
        expect(subject.can?(:edit, MediaObject)).to eq false
        expect(subject.can?(:update, MediaObject)).to eq false
        expect(subject.can?(:destroy, MediaObject)).to eq false
        expect(subject.can?(:update_access_control, MediaObject)).to eq false
        expect(subject.can?(:unpublish, MediaObject)).to eq false

        expect(subject.can?(:create, SpeedyAF::Proxy::MediaObject)).to eq false
        expect(subject.can?(:read, SpeedyAF::Proxy::MediaObject)).to eq true
        expect(subject.can?(:edit, SpeedyAF::Proxy::MediaObject)).to eq false
        expect(subject.can?(:update, SpeedyAF::Proxy::MediaObject)).to eq false
        expect(subject.can?(:destroy, SpeedyAF::Proxy::MediaObject)).to eq false
        expect(subject.can?(:update_access_control, SpeedyAF::Proxy::MediaObject)).to eq false
        expect(subject.can?(:unpublish, SpeedyAF::Proxy::MediaObject)).to eq false

        expect(subject.can?(:create, MasterFile)).to eq false
        expect(subject.can?(:read, MasterFile)).to eq true
        expect(subject.can?(:edit, MasterFile)).to eq false
        expect(subject.can?(:update, MasterFile)).to eq false
        expect(subject.can?(:destroy, MasterFile)).to eq false

        expect(subject.can?(:create, SpeedyAF::Proxy::MasterFile)).to eq false
        expect(subject.can?(:read, SpeedyAF::Proxy::MasterFile)).to eq true
        expect(subject.can?(:edit, SpeedyAF::Proxy::MasterFile)).to eq false
        expect(subject.can?(:update, SpeedyAF::Proxy::MasterFile)).to eq false
        expect(subject.can?(:destroy, SpeedyAF::Proxy::MasterFile)).to eq false

        expect(subject.can?(:create, Derivative)).to eq false
        expect(subject.can?(:read, Derivative)).to eq true
        expect(subject.can?(:edit, Derivative)).to eq false
        expect(subject.can?(:update, Derivative)).to eq false
        expect(subject.can?(:destroy, Derivative)).to eq false

        expect(subject.can?(:create, SpeedyAF::Proxy::Derivative)).to eq false
        expect(subject.can?(:read, SpeedyAF::Proxy::Derivative)).to eq true
        expect(subject.can?(:edit, SpeedyAF::Proxy::Derivative)).to eq false
        expect(subject.can?(:update, SpeedyAF::Proxy::Derivative)).to eq false
        expect(subject.can?(:destroy, SpeedyAF::Proxy::Derivative)).to eq false

        expect(subject.can?(:create, Admin::Collection)).to eq false
        expect(subject.can?(:read, Admin::Collection)).to eq true
        expect(subject.can?(:edit, Admin::Collection)).to eq false
        expect(subject.can?(:update, Admin::Collection)).to eq false
        expect(subject.can?(:destroy, Admin::Collection)).to eq false
        expect(subject.can?(:update_unit, Admin::Collection)).to eq false
        expect(subject.can?(:update_access_control, Admin::Collection)).to eq false
        expect(subject.can?(:update_managers, Admin::Collection)).to eq false
        expect(subject.can?(:update_editors, Admin::Collection)).to eq false
        expect(subject.can?(:update_depositors, Admin::Collection)).to eq false

        expect(subject.can?(:create, SpeedyAF::Proxy::Admin::Collection)).to eq false
        expect(subject.can?(:read, SpeedyAF::Proxy::Admin::Collection)).to eq true
        expect(subject.can?(:edit, SpeedyAF::Proxy::Admin::Collection)).to eq false
        expect(subject.can?(:update, SpeedyAF::Proxy::Admin::Collection)).to eq false
        expect(subject.can?(:destroy, SpeedyAF::Proxy::Admin::Collection)).to eq false
        expect(subject.can?(:update_unit, SpeedyAF::Proxy::Admin::Collection)).to eq false
        expect(subject.can?(:update_access_control, SpeedyAF::Proxy::Admin::Collection)).to eq false
        expect(subject.can?(:update_managers, SpeedyAF::Proxy::Admin::Collection)).to eq false
        expect(subject.can?(:update_editors, SpeedyAF::Proxy::Admin::Collection)).to eq false
        expect(subject.can?(:update_depositors, SpeedyAF::Proxy::Admin::Collection)).to eq false
      end
    end

    context 'with read-only disabled' do
      let(:read_only) { false }

      it 'has all abilities' do
        expect(subject.can?(:manage, :all)).to eq true
        expect(subject.can?(:manage, MediaObject)).to eq true
        expect(subject.can?(:discover_everything, MediaObject)).to eq true

        expect(subject.can?(:read, media_object)).to eq true
        expect(subject.can?(:read, collection)).to eq true

        expect(subject.can?(:create, MediaObject)).to eq true
        expect(subject.can?(:read, MediaObject)).to eq true
        expect(subject.can?(:edit, MediaObject)).to eq true
        expect(subject.can?(:update, MediaObject)).to eq true
        expect(subject.can?(:destroy, MediaObject)).to eq true
        expect(subject.can?(:update_access_control, MediaObject)).to eq true
        expect(subject.can?(:unpublish, MediaObject)).to eq true

        expect(subject.can?(:create, SpeedyAF::Proxy::MediaObject)).to eq true
        expect(subject.can?(:read, SpeedyAF::Proxy::MediaObject)).to eq true
        expect(subject.can?(:edit, SpeedyAF::Proxy::MediaObject)).to eq true
        expect(subject.can?(:update, SpeedyAF::Proxy::MediaObject)).to eq true
        expect(subject.can?(:destroy, SpeedyAF::Proxy::MediaObject)).to eq true
        expect(subject.can?(:update_access_control, SpeedyAF::Proxy::MediaObject)).to eq true
        expect(subject.can?(:unpublish, SpeedyAF::Proxy::MediaObject)).to eq true
 
        expect(subject.can?(:create, MasterFile)).to eq true
        expect(subject.can?(:read, MasterFile)).to eq true
        expect(subject.can?(:edit, MasterFile)).to eq true
        expect(subject.can?(:update, MasterFile)).to eq true
        expect(subject.can?(:destroy, MasterFile)).to eq true

        expect(subject.can?(:create, SpeedyAF::Proxy::MasterFile)).to eq true
        expect(subject.can?(:read, SpeedyAF::Proxy::MasterFile)).to eq true
        expect(subject.can?(:edit, SpeedyAF::Proxy::MasterFile)).to eq true
        expect(subject.can?(:update, SpeedyAF::Proxy::MasterFile)).to eq true
        expect(subject.can?(:destroy, SpeedyAF::Proxy::MasterFile)).to eq true

        expect(subject.can?(:create, Derivative)).to eq true
        expect(subject.can?(:read, Derivative)).to eq true
        expect(subject.can?(:edit, Derivative)).to eq true
        expect(subject.can?(:update, Derivative)).to eq true
        expect(subject.can?(:destroy, Derivative)).to eq true

        expect(subject.can?(:create, SpeedyAF::Proxy::Derivative)).to eq true
        expect(subject.can?(:read, SpeedyAF::Proxy::Derivative)).to eq true
        expect(subject.can?(:edit, SpeedyAF::Proxy::Derivative)).to eq true
        expect(subject.can?(:update, SpeedyAF::Proxy::Derivative)).to eq true
        expect(subject.can?(:destroy, SpeedyAF::Proxy::Derivative)).to eq true

        expect(subject.can?(:create, Admin::Collection)).to eq true
        expect(subject.can?(:read, Admin::Collection)).to eq true
        expect(subject.can?(:edit, Admin::Collection)).to eq true
        expect(subject.can?(:update, Admin::Collection)).to eq true
        expect(subject.can?(:destroy, Admin::Collection)).to eq true
        expect(subject.can?(:update_unit, Admin::Collection)).to eq true
        expect(subject.can?(:update_access_control, Admin::Collection)).to eq true
        expect(subject.can?(:update_managers, Admin::Collection)).to eq true
        expect(subject.can?(:update_editors, Admin::Collection)).to eq true
        expect(subject.can?(:update_depositors, Admin::Collection)).to eq true

        expect(subject.can?(:create, SpeedyAF::Proxy::Admin::Collection)).to eq true
        expect(subject.can?(:read, SpeedyAF::Proxy::Admin::Collection)).to eq true
        expect(subject.can?(:edit, SpeedyAF::Proxy::Admin::Collection)).to eq true
        expect(subject.can?(:update, SpeedyAF::Proxy::Admin::Collection)).to eq true
        expect(subject.can?(:destroy, SpeedyAF::Proxy::Admin::Collection)).to eq true
        expect(subject.can?(:update_unit, SpeedyAF::Proxy::Admin::Collection)).to eq true
        expect(subject.can?(:update_access_control, SpeedyAF::Proxy::Admin::Collection)).to eq true
        expect(subject.can?(:update_managers, SpeedyAF::Proxy::Admin::Collection)).to eq true
        expect(subject.can?(:update_editors, SpeedyAF::Proxy::Admin::Collection)).to eq true
        expect(subject.can?(:update_depositors, SpeedyAF::Proxy::Admin::Collection)).to eq true
      end
    end
  end
end
