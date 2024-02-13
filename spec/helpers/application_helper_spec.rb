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

describe ApplicationHelper do
  describe "#active_for_controller" do
    before(:each) do
      allow(helper).to receive(:params).and_return({controller: 'media_objects'})
    end
    it "should return 'active' for matching controller names" do
      expect(helper.active_for_controller('media_objects')).to eq('active')
    end
    it "should return '' for non-matching controller names" do
      expect(helper.active_for_controller('master_files')).to eq('')
    end
    it "should handle name-spaced controllers" do
      allow(helper).to receive(:params).and_return({controller: 'admin/groups'})
      expect(helper.active_for_controller('admin/groups')).to eq('active')
      expect(helper.active_for_controller('groups')).to eq('')
    end
  end

  describe "#stream_label_for" do
    it "should return the label first if it is available" do
      master_file = FactoryBot.build(:master_file, title: 'Label')
      expect(master_file.file_location).not_to be_nil
      expect(master_file.title).not_to be_nil
      expect(helper.stream_label_for(master_file)).to eq('Label')
    end
    it "should return the filename second if it is available" do
      master_file = FactoryBot.build(:master_file, title: nil)
      expect(master_file.file_location).not_to be_nil
      expect(master_file.title).to be_nil
      expect(helper.stream_label_for(master_file)).to eq(File.basename(master_file.file_location))
    end
    it "should handle empty file_locations and labels" do
      master_file = FactoryBot.build(:master_file, file_location: nil, title: nil)
      expect(master_file.file_location).to be_nil
      expect(master_file.title).to be_nil
      expect(helper.stream_label_for(master_file)).to eq(master_file.id)
    end
  end

  describe '.lti_share_url_for' do
    it 'forms a proper lti share url for media objects' do
      media_object = FactoryBot.create(:media_object)
      expect(helper.lti_share_url_for(media_object)).to eq "http://test.host/users/auth/lti/callback?target_id=#{media_object.id}"
    end
    it 'forms a proper lti share url for master files' do
      master_file = FactoryBot.create(:master_file)
      expect(helper.lti_share_url_for(master_file)).to eq "http://test.host/users/auth/lti/callback?target_id=#{master_file.id}"
    end
    it 'forms a proper lti share url for playlists' do
      playlist = FactoryBot.create(:playlist)
      expect(helper.lti_share_url_for(playlist)).to eq "http://test.host/users/auth/lti/callback?target_id=#{playlist.to_gid_param}"
    end
    it 'forms a proper lti share url for timelines' do
      timeline = FactoryBot.create(:timeline)
      expect(helper.lti_share_url_for(timeline)).to eq "http://test.host/users/auth/lti/callback?target_id=#{timeline.to_gid_param}"
    end
  end

  describe "#search_result_label" do
    it "should not include a duration string if it would be 0" do
      mo_solr_doc = {"title_tesi" => "my_title"}
      expect(helper.search_result_label(mo_solr_doc)).not_to include("(00:00)")
    end
    it "should return formatted title if duration is present" do
      mo_solr_doc = {"title_tesi" => "my_title", "duration_ssi" => "1000"}
      expect(helper.search_result_label(mo_solr_doc)).to eq("my_title (00:01)")
    end
    it "should return id when no title" do
      mo_solr_doc = { id: "avalon:123" }
      expect(helper.search_result_label(mo_solr_doc)).to eq("avalon:123")
    end
  end

  describe "#truncate_center" do
    it "should return empty string if empty string received" do
      expect(helper.truncate_center("", 5)).to eq ""
    end
    it "should truncate with no end length provided" do
      expect(helper.truncate_center("This is my very long test string", 16)).to eq "This is ...tring"
    end
    it "should truncate with end length" do
      expect(helper.truncate_center("This is my very long test string", 20, 6)).to eq "This is my ...string"
    end
    it "shouldn't truncate if not needed" do
      expect(helper.truncate_center("This string is short", 20)).to eq "This string is short"
    end
  end

  describe "#milliseconds_to_formatted_time" do
    it "should return correct values" do
      expect(helper.milliseconds_to_formatted_time(0)).to eq("00:00")
      expect(helper.milliseconds_to_formatted_time(1000)).to eq("00:01")
      expect(helper.milliseconds_to_formatted_time(60000)).to eq("01:00")
      expect(helper.milliseconds_to_formatted_time(3600000)).to eq("1:00:00")
      expect(helper.milliseconds_to_formatted_time(1123)).to eq("00:01.123")
      expect(helper.milliseconds_to_formatted_time(1123, false)).to eq("00:01")
    end
  end

  describe "#git_commit_info" do
    it "should return commit info in specified pattern" do
      #expect(helper.git_commit_info()).to eq("x")
      skip "Grit gem is abandoned and thowing errors. Replace with libgit2/rugged"

    end
  end

  describe "#image_for" do
    # image_for expects hash keys as labels, not strings
    it "should return nil" do
      doc = {"avalon_resource_type_ssim" => [] }
      expect(helper.image_for(doc)).to eq(nil)
    end
    it "should return audio icon" do
      doc = {"avalon_resource_type_ssim" => ['Sound Recording', 'Sound Recording'] }
      expect(helper.image_for(doc).start_with?('/assets/audio_icon')).to be_truthy
    end
    it "should return video icon" do
      doc = {"avalon_resource_type_ssim" => ['Moving Image'] }
      expect(helper.image_for(doc).start_with?('/assets/video_icon')).to be_truthy
    end
    it "should return hybrid icon" do
      doc = {"avalon_resource_type_ssim" => ['Moving Image', 'Sound Recording'] }
      expect(helper.image_for(doc).start_with?('/assets/hybrid_icon')).to be_truthy
    end
    it "should return nil when only unprocessed video" do
      doc = {"section_id_ssim" => ['1'], "avalon_resource_type_ssim" => [] }
      expect(helper.image_for(doc)).to eq(nil)
    end
    it "should return thumbnail" do
      doc = {"section_id_ssim" => ['1'], "avalon_resource_type_ssim" => ['Moving Image'] }
      expect(helper.image_for(doc)).to eq('/master_files/1/thumbnail')
    end
  end

  describe "#display_metadata" do
    it "should return nil for a blank value" do
      expect(helper.display_metadata("Label", [""])).to be_nil
    end

    it "should return a pluralized label and semicolon-separated string for multiple values" do
      expect(helper.display_metadata("Label", ["Value1", "Value2"])).to eq("<dt>Labels</dt><dd><pre>Value1; Value2</pre></dd>")
    end

    it "should return a default value if provided" do
      expect(helper.display_metadata("Label", [""], "Default value")).to eq("<dt>Label</dt><dd><pre>Default value</pre></dd>")
    end
  end

  describe "#pretty_time" do
    it 'returns a formatted time' do
      expect(helper.pretty_time(0)).to eq '00:00:00.000'
      expect(helper.pretty_time(1)).to eq '00:00:00.001'
      expect(helper.pretty_time(9)).to eq '00:00:00.009'
      expect(helper.pretty_time(10)).to eq '00:00:00.010'
      expect(helper.pretty_time(101)).to eq '00:00:00.101'
      expect(helper.pretty_time(1010)).to eq '00:00:01.010'
      expect(helper.pretty_time(10101)).to eq '00:00:10.101'
      expect(helper.pretty_time(101010)).to eq '00:01:41.010'
      expect(helper.pretty_time(1010101)).to eq '00:16:50.101'
      expect(helper.pretty_time(10101010)).to eq '02:48:21.010'
      expect(helper.pretty_time(0.0)).to eq '00:00:00.000'
      expect(helper.pretty_time(0.1)).to eq '00:00:00.000'
      expect(helper.pretty_time(1.1)).to eq '00:00:00.001'
      expect(helper.pretty_time(-1000)).to eq '00:00:00.000'
      expect(helper.pretty_time('0')).to eq '00:00:00.000'
      expect(helper.pretty_time('1')).to eq '00:00:00.001'
      expect(helper.pretty_time('10101010')).to eq '02:48:21.010'
      expect(helper.pretty_time('-1000')).to eq '00:00:00.000'
      expect(helper.pretty_time('0.0')).to eq '00:00:00.000'
      expect(helper.pretty_time('0.1')).to eq '00:00:00.000'
      expect(helper.pretty_time('1.1')).to eq '00:00:00.001'
    end

    it 'returns an exception when not a number' do
      expect { helper.pretty_time(nil) }.to raise_error(TypeError)
      expect { helper.pretty_time('foo') }.to raise_error(ArgumentError)
    end
  end

  describe "#object_supplemental_file_path" do
    let(:supplemental_file) { FactoryBot.create(:supplemental_file) }
    let(:supplemental_files_json) { [supplemental_file.to_global_id.to_s].to_json }

    let(:master_file) { FactoryBot.create(:master_file, supplemental_files_json: supplemental_files_json) }
    let(:media_object) { FactoryBot.create(:media_object, supplemental_files_json: supplemental_files_json) }

    context 'MasterFile' do
      it 'returns masterfile_supplemental_file_path' do
        expect(helper.object_supplemental_file_path(master_file, supplemental_file)).to eq(
          "/master_files/#{master_file.id}/supplemental_files/#{supplemental_file.id}"
        )
      end
    end

    context 'SpeedyAF(MasterFile)' do
      let(:presenter) { SpeedyAF::Proxy::MasterFile.find(master_file.id) }

      it 'returns masterfile_supplemental_file_path' do
        expect(helper.object_supplemental_file_path(presenter, supplemental_file)).to eq(
          "/master_files/#{master_file.id}/supplemental_files/#{supplemental_file.id}"
        )
      end
    end

    context 'MediaObject' do
      it 'returns mediaobject_supplemental_file_path' do
        expect(helper.object_supplemental_file_path(media_object, supplemental_file)).to eq(
          "/media_objects/#{media_object.id}/supplemental_files/#{supplemental_file.id}"
        )
      end
    end
  end
end
