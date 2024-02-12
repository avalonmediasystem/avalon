# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

describe SupplementalFile do
  let(:subject) { FactoryBot.create(:supplemental_file) }

  describe 'validations' do
    describe 'file type' do
      context 'non-caption file' do
        let(:subject) { FactoryBot.create(:supplemental_file, :with_attached_file) }
        it 'should skip validation' do
          expect(subject.valid?).to be_truthy
        end
      end
      context 'VTT/SRT caption file' do
        let(:subject) { FactoryBot.create(:supplemental_file, :with_caption_file, :with_caption_tag) }
        it 'should validate' do
          expect(subject.valid?).to be_truthy
        end
      end
      context 'non-VTT/non-SRT caption file' do
        let(:subject) { FactoryBot.build(:supplemental_file, :with_attached_file, :with_caption_tag) }
        it 'should not validate' do
          expect(subject.valid?).to be_falsey
          expect(subject.errors[:file_type]).not_to be_empty
        end
      end
    end

    describe 'language' do
      it 'should validate valid language' do
        subject.language = 'eng'
        expect(subject.valid?).to be_truthy
      end
      it 'should not validate invalid language' do
        subject.language = 'engl'
        expect(subject.valid?).to be_falsey
      end
    end
  end

  it "stores no tags by default" do
    expect(subject.tags).to match_array([])
  end

  context "with valid tags" do
    let(:subject) { FactoryBot.create(:supplemental_file, :with_caption_file)}
    let(:tags) { ["transcript", "caption", "machine_generated"] }

    it "can store tags" do
      subject.tags = tags
      subject.save
      expect(subject.reload.tags).to match_array(tags)
    end
  end

  context "with invalid tags" do
    let(:bad_tags) { ["unallowed"] }

    it "does not store tags" do
      subject.tags = bad_tags
      expect(subject.save).to be_falsey
      expect(subject.errors.messages[:tags]).to include("unallowed is not an allowed value")
    end
  end

  context 'language' do
    it "can be edited" do
      subject.language = 'ger'
      subject.save
      expect(subject.reload.language).to eq "ger"
    end
  end
end
