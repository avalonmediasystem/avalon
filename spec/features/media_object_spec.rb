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

describe 'MediaObject' do
  after { Warden.test_reset! }
  let(:media_object) { FactoryBot.build(:media_object).tap {|mo| mo.workflow.last_completed_step = "resource-description"} }
  let!(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }
  before :each do
    @user = FactoryBot.create(:administrator)
    login_as @user, scope: :user
  end
  it 'can visit a media object' do
    media_object.save
    visit media_object_path(media_object)
    expect(page.status_code). to eq(200)
    expect(page.has_content?('Default Unit')).to be_truthy
  end
  describe 'metadata display' do
    it 'displays the title properly' do
      title = 'Hello World'
      media_object.title = title
      media_object.save
      visit media_object_path(media_object)
      expect(page.has_content?(title)).to be_truthy
    end
    it 'displays the date properly' do
      date = '1997'
      media_object.date_issued = date
      media_object.save
      visit media_object_path(media_object)
      expect(page.has_content?(date)).to be_truthy
    end
    it 'displays the main contributors properly' do
      media_object.save
      on_save_mc = media_object.creator.first
      visit media_object_path(media_object)
      expect(page.has_content?(on_save_mc)).to be_truthy
    end
    it 'displays the summary properly' do
      summary = 'This is a really awesome object'
      media_object.abstract = summary
      media_object.save
      visit media_object_path(media_object)
      expect(page.has_content?(summary)).to be_truthy
    end
    it 'displays the contributors properly' do
      contributor = 'Jamie Lannister'
      media_object.contributor = [contributor]
      media_object.save
      visit media_object_path(media_object)
      expect(page.has_content?(contributor)).to be_truthy
    end
    context 'cdl is enabled' do
      before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(true) }
      before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(true) }
      it 'displays the lending period properly' do
        lending_period = 90000
        media_object.lending_period = lending_period
        media_object.save
        visit media_object_path(media_object)
        expect(page.has_content?('1 day 1 hour')).to be_truthy
      end
    end
    context 'cdl is disabled' do
      before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(false) }
      it 'does not display the lending period' do
        lending_period = 90000
        media_object.lending_period = lending_period
        media_object.save
        visit media_object_path(media_object)
        expect(page.has_content?('1 day 1 hour')).to be_falsey
      end
    end
  end
  describe 'displays cdl controls' do
    before { FactoryBot.create(:checkout, media_object_id: media_object.id, user_id: @user.id).save }
    context 'enabled at application level' do
      before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(true) }
      before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(true) }
      let(:available_media_object) { FactoryBot.build(:media_object) }
      let!(:mf) { FactoryBot.create(:master_file, media_object: available_media_object) }

      context 'displays embedded player' do
        it 'with proper text when available' do
          visit media_object_path(available_media_object)
          expect(page).to have_content('Borrow this item to access media resources.')
          expect(page).to have_selector(:link_or_button, 'Borrow for 14 days')
        end
        it 'with proper text when not available' do
          # Checkout the available media object with a different user
          normal_user = FactoryBot.create(:user)
          FactoryBot.create(:checkout, media_object_id: available_media_object.id, user_id: normal_user.id).save

          visit media_object_path(available_media_object)
          expect(page.has_content?('This resource is currently checked out by another user.')).to be_truthy
          expect(page.has_content?('This item is due to be returned on')).to be_truthy
        end
      end

      it 'displays countdown timer when checked out' do
        visit media_object_path(media_object)
        expect(page.has_content?('Time remaining:')).to be_truthy
        expect(page).to have_selector(:link_or_button, 'Return now')
      end
    end

    context 'when cdl is turned off at collection level' do
      let(:collection) { FactoryBot.create(:collection, cdl_enabled: false) }
      let(:available_media_object) { FactoryBot.create(:media_object, collection_id: collection.id) }
      it 'does not display cdl text' do
        visit media_object_path(available_media_object)
        expect(page).not_to have_content('Borrow this item to access media resources.')
        expect(page).not_to have_selector(:link_or_button, 'Borrow for 14 days')
      end
    end

    context 'disabled for application, enabled for collection' do
      before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(true) }
      before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(false) }
      let(:collection) { FactoryBot.create(:collection, cdl_enabled: true) }
      let(:available_media_object) { FactoryBot.create(:media_object, collection_id: collection.id) }
      let!(:mf) { FactoryBot.create(:master_file, media_object: available_media_object) }

      context 'displays embedded player' do
        it 'with proper text when available' do
          visit media_object_path(available_media_object)
          expect(page).to have_content('Borrow this item to access media resources.')
          expect(page).to have_selector(:link_or_button, 'Borrow for 14 days')
        end
        it 'with proper text when not available' do
          # Checkout the available media object with a different user
          normal_user = FactoryBot.create(:user)
          FactoryBot.create(:checkout, media_object_id: available_media_object.id, user_id: normal_user.id).save

          visit media_object_path(available_media_object)
          expect(page.has_content?('This resource is currently checked out by another user.')).to be_truthy
          expect(page.has_content?('This item is due to be returned on')).to be_truthy
        end
        it 'displays countdown timer when checked out' do
          FactoryBot.create(:checkout, media_object_id: available_media_object.id, user_id: @user.id).save

          visit media_object_path(available_media_object)
          expect(page.has_content?('Time remaining:')).to be_truthy
          expect(page).to have_selector(:link_or_button, 'Return now')
        end
      end
    end
  end

  describe 'with transcript file' do
    let(:supplemental_file) { FactoryBot.create(:supplemental_file) }
    let(:master_file) { FactoryBot.create(:master_file, supplemental_files: [supplemental_file], media_object: media_object) }
    let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_transcript_file, :with_transcript_tag, label: 'transcript') }

    context 'when CDL is disabled at application level' do
      before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(false) }

      it 'renders the transcript viewer' do
        media_object.save
        visit media_object_path(media_object)
        expect(page.has_css?('div[data-react-class="ReactIIIFTranscript"]')).to be_truthy
      end
    end

    context 'when CDL is disabled at collection level' do
      before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(true) }
      before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(false) }

      it 'renders the transcript viewer' do
        media_object.save
        visit media_object_path(media_object)
        expect(page.has_css?('div[data-react-class="ReactIIIFTranscript"]')).to be_truthy
      end
    end

    context 'when CDL is enabled' do
      before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(true) }
      before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(true) }

      context 'unchecked out item' do
        it 'does not render the transcript viewer' do
          media_object.save
          visit media_object_path(media_object)
          expect(page.has_css?('div[data-react-class="ReactIIIFTranscript"]')).to be_falsey
        end
      end
      context 'checked out item' do
        before { FactoryBot.create(:checkout, media_object_id: media_object.id, user_id: @user.id).save }

        it 'renders the transcript viewer' do
          media_object.save
          visit media_object_path(media_object)
          expect(page.has_css?('div[data-react-class="ReactIIIFTranscript"]')).to be_truthy
        end
      end
    end
  end
end
