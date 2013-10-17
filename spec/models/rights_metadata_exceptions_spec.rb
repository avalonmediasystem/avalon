# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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
require 'cancan/matchers'

describe RightsMetadataExceptions do
  let! (:media_object) { FactoryGirl.create(:media_object) }

  it "#user_exceptions" do
  	users = (1..3).collect { Faker::Internet.email }
  	media_object.user_exceptions = users
  	media_object.user_exceptions.should == users
  end

  it "#group_exceptions" do
  	groups = (1..3).collect { Faker::Lorem.words(3).join(' ').titleize }
  	media_object.group_exceptions = groups
  	media_object.group_exceptions.should == groups
  end

  it "should supply exceptions_access to all RightsMetadata descendants" do
    Hydra::Datastream::RightsMetadata.terminology.xpath_for(:exceptions_access).should be_present
    Hydra::Datastream::RightsMetadata.descendants.each { |desc|
      desc.terminology.xpath_for(:exceptions_access).should be_present
    }
  end
end
