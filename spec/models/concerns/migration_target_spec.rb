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

describe MigrationTarget do

  before(:all) do
    class Foo < ActiveFedora::Base
      include MigrationTarget
    end
  end

  after(:all) { Object.send(:remove_const, :Foo) }

  subject { Foo.new }

  it 'defines migrated_from' do
    expect(subject.attributes).to include("migrated_from")
  end

  it 'solrizes as symbol' do
    subject.migrated_from = ["avalon:1234"]
    expect(subject.to_solr['migrated_from_ssim']).to match_array subject.migrated_from
  end
end
