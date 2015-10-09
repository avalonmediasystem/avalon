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

describe CachingSimpleDatastream do
  
  before do
    class CachingModel < ActiveFedora::Base
      has_metadata name: 'primary', :type => CachingSimpleDatastream.create(self) do |d|
        d.field :one, :string
        d.field :two, :integer
      end
      
      has_metadata name: 'secondary', :type => CachingSimpleDatastream.create(self) do |d|
        d.field :three, :boolean
        d.field :four, :date
      end
      
      has_attributes :one, :two, datastream: :primary
      has_attributes :three, :four, datastream: :secondary
    end
  end
  
  after do
    Object.send(:remove_const, :CachingModel)
  end
  
  subject { CachingModel.new }
  
  it "should know the solr names for its attributes" do
    expect(subject.primary.primary_solr_name(:one)).to eq(ActiveFedora::SolrService.solr_name('one', type: :string))
    expect(subject.primary.primary_solr_name(:two)).to eq(ActiveFedora::SolrService.solr_name('two', type: :integer))
    expect(subject.secondary.primary_solr_name(:three)).to eq(ActiveFedora::SolrService.solr_name('three', type: :boolean))
    expect(subject.secondary.primary_solr_name(:four)).to eq(ActiveFedora::SolrService.solr_name('four', type: :date))
  end
  
  it "should raise an error on an unknown field name" do
    expect { subject.primary.primary_solr_name(:five) }.to raise_error(CachingSimpleDatastream::FieldError)
  end
end
