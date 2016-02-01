# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

require 'spec_helper'

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
      master_file = FactoryGirl.build(:master_file, label: 'Label')
      expect(master_file.file_location).not_to be_nil
      expect(master_file.label).not_to be_nil
      expect(helper.stream_label_for(master_file)).to eq('Label')
    end
    it "should return the filename second if it is available" do
      master_file = FactoryGirl.build(:master_file, label: nil)
      expect(master_file.file_location).not_to be_nil
      expect(master_file.label).to be_nil
      expect(helper.stream_label_for(master_file)).to eq(File.basename(master_file.file_location))
    end
    it "should handle empty file_locations and labels" do
      master_file = FactoryGirl.build(:master_file, file_location: nil, label: nil)
      expect(master_file.file_location).to be_nil
      expect(master_file.label).to be_nil
      expect(helper.stream_label_for(master_file)).to eq(master_file.pid)
    end
  end

  describe "#search_result_label" do
    it "should not include a duration string if it would be 0" do
      mo_solr_doc = {"title_tesi" => "my_title"}
      expect(helper.search_result_label(mo_solr_doc)).not_to include("(00:00)")
    end
    it "should return formatted title if duration is present" do
      mo_solr_doc = {"title_tesi" => "my_title", "duration_tesim" => ["1000"]}
      expect(helper.search_result_label(mo_solr_doc)).to eq("my_title (00:01)")
    end
    it "should return pid when no title" do
      mo_solr_doc = {}
      allow(mo_solr_doc).to receive(:id) {"avalon:123"}
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
      doc = {"avalon_resource_type_tesim" => [] }
      expect(helper.image_for(doc)).to eq(nil)
    end
    it "should return audio icon" do
      doc = {"avalon_resource_type_tesim" => ['sound recording 2', 'sound recording 1'] }
      expect(helper.image_for(doc)).to eq('/assets/audio_icon.png')
    end
    it "should return video icon" do
      doc = {"avalon_resource_type_tesim" => ['moving image 1'] }
      expect(helper.image_for(doc)).to eq('/assets/video_icon.png')
    end
    it "should return hybrid icon" do
      doc = {"avalon_resource_type_tesim" => ['moving image 1', 'sound recording 1'] }
      expect(helper.image_for(doc)).to eq('/assets/hybrid_icon.png')
    end
    it "should return nil when only unprocessed video" do
      doc = {"section_pid_tesim" => ['1'], "avalon_resource_type_tesim" => [] }
      expect(helper.image_for(doc)).to eq(nil)
    end
    it "should return thumbnail" do
      doc = {"section_pid_tesim" => ['1'], "avalon_resource_type_tesim" => ['moving image 1'] }
      expect(helper.image_for(doc)).to eq('/master_files/1/thumbnail')
    end
  end
end
