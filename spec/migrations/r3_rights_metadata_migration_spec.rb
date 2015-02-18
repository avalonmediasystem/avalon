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
require File.join(Rails.root, 'db', 'migrate', '20140306160513_remove_hydra_migrate.rb')
require File.join(Rails.root, 'db', 'migrate', '20140306225510_r2_content_to_r3.rb')
 
describe R2ContentToR3 do
  before(:each) do
    #load fixture
    ActiveFedora::FixtureLoader.new(File.join(Rails.root, 'spec', 'fixtures', 'r2')).import_and_index('avalon:1134')
  end

  after(:each) do
    #unload fixture
    ActiveFedora::FixtureLoader.delete('avalon:1134')
  end

  describe '#up' do
    subject(:mediaobject) {MediaObject.find('avalon:1134')}
    before(:each) do
      ActiveRecord::Migration.verbose = false
      RemoveHydraMigrate.new.up
      R2ContentToR3.new.up
    end

    it "should add user exceptions to read access" do
      expect(mediaobject.read_users).to include('cjcolvar')
    end

    it "should add group exceptions to read access" do
      expect(mediaobject.read_groups).to include('TestGroup')
      expect(mediaobject.read_groups.size).to eq 3
    end

    it "should remove exceptions access node" do
      expect(mediaobject.rightsMetadata.ng_xml.xpath("//rm:access[@type='exceptions']", {
        'rm' => 'http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1'})).to be_empty
    end

    it "should not attempt to remove exceptions if node does not exist" do
      @mediaobject = FactoryGirl.create(:media_object)
      expect{R2ContentToR3.new.up}.not_to raise_error
    end
  end
end
