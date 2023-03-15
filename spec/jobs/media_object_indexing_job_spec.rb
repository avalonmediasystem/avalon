# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

describe MediaObjectIndexingJob do
  let(:job) { MediaObjectIndexingJob.new }

  describe "perform" do
    let!(:media_object) { FactoryBot.create(:media_object) }
    let!(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }

    it 'indexes the media object including master_file fields' do
      before_doc = ActiveFedora::SolrService.query("id:#{media_object.id}").first
      expect(before_doc["section_id_ssim"]).to be_blank
      job.perform(media_object.id)
      after_doc = ActiveFedora::SolrService.query("id:#{media_object.id}").first
      expect(after_doc["section_id_ssim"]).to eq [master_file.id]
    end
  end
end
