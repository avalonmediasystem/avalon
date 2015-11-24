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

describe "UniquenessValidator" do

  let(:solr_field) {"title_tesim"}
  let(:validator) {UniquenessValidator.new({:attributes => [:title], :solr_name => solr_field})}

  before(:each) do
    @record = double(pid:"avalon:1")
    allow(@record).to receive("errors").and_return([])
  end

  it "should raise an exception if solr_name option is missing" do
     expect{UniquenessValidator.new({attributes: [:title]})}.to raise_error ArgumentError
  end

  it "should not return errors when field is unique" do
    allow(validator).to receive("find_doc").and_return(nil)
    expect(@record).not_to receive('errors')  
    validator.validate_each(@record, "title", "new_title")
  end

  it "should not return errors when field is unique but record is the same" do
    doc = double(pid: "avalon:1")
    allow(validator).to receive("find_doc").and_return(doc)
    expect(@record).not_to receive('errors')
    validator.validate_each(@record, "title", "new_title")
  end

  it "should return erros when field is not unique" do
    doc = double(pid: "avalon:2")
    allow(validator).to receive("find_doc").and_return(doc)
    expect(@record.errors).to receive('add')
    validator.validate_each(@record, "title", "old_title")
  end  

  describe "#find_doc" do
    let (:klass) {@record.class}
    let (:value) {"old_title"}

    it "should use the solr field name and supplied values" do
      relation = double()
      allow(relation).to receive("first")
      expect(klass).to receive("where").once.with(solr_field => value).and_return(relation)
      validator.find_doc(klass, value)
    end
    it "should return one record when present" do
      doc = double(pid: "avalon:1")
      relation = double()
      allow(relation).to receive("first").and_return(doc)
      allow(klass).to receive("where").and_return(relation)
      expect(validator.find_doc(klass, value)).to be_an_instance_of klass
    end
    it "should return nil when not present" do
      relation = double()
      allow(relation).to receive("first").and_return(nil)
      allow(klass).to receive("where").and_return(relation)
      expect(validator.find_doc(klass, value)).to be_nil
    end
  end
end
