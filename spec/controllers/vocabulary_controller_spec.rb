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
require 'fileutils'

describe VocabularyController, type: :controller do
  render_views

  before(:all) {
    FileUtils.cp_r 'spec/fixtures/controlled_vocabulary.yml', 'spec/fixtures/controlled_vocabulary.yml.tmp'
    Avalon::ControlledVocabulary.class_variable_set :@@path, Rails.root.join('spec/fixtures/controlled_vocabulary.yml.tmp') 
  }
  after(:all) {
    File.delete('spec/fixtures/controlled_vocabulary.yml.tmp')
  }
  
  describe "#index" do
    it "should return vocabulary for entire app" do
      get 'index'
      expect(JSON.parse(response.body)).to include('units','note_types','identifier_types')
    end
  end
  describe "#show" do
    it "should return a particular vocabulary" do
      get 'show', id: :units
      expect(JSON.parse(response.body)).to include('Default Unit')
    end
    it "should return 404 if requested vocabulary not present" do
      get 'show', id: :doesnt_exist
      expect(response.status).to eq(404)
    end
  end
  describe "#update" do
    it "should add unit to controlled vocabulary" do
      put 'update', id: :units, entry: 'New Unit'
      expect(Avalon::ControlledVocabulary.vocabulary[:units]).to include("New Unit")
    end
    it "should return 404 if requested vocabulary not present" do
      put 'update', id: :doesnt_exist, entry: 'test'
      expect(response.status).to eq(404)
    end
    it "should return 422 if no new value sent" do
      put 'update', id: :units
      expect(response.status).to eq(422)
    end
    it "should return 422 if update fails" do
      allow(Avalon::ControlledVocabulary).to receive(:vocabulary=).and_return(false)
      put 'update', id: :units
      expect(response.status).to eq(422)
    end
  end

end
