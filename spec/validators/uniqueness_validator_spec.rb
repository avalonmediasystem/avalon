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
    @record.stub("errors").and_return([])
  end

  it "should raise an exception if solr_name option is missing" do
     expect{UniquenessValidator.new({attributes: [:title]})}.to raise_error ArgumentError
  end

  it "should not return errors when field is unique" do
    validator.stub("find_doc").and_return(nil)
    @record.should_not_receive('errors')  
    validator.validate_each(@record, "title", "new_title")
  end

  it "should not return errors when field is unique but record is the same" do
    doc = double(pid: "avalon:1")
    validator.stub("find_doc").and_return(doc)
    @record.should_not_receive('errors')
    validator.validate_each(@record, "title", "new_title")
  end

  it "should return erros when field is not unique" do
    doc = double(pid: "avalon:2")
    validator.stub("find_doc").and_return(doc)
    @record.errors.should_receive('add')
    validator.validate_each(@record, "title", "old_title")
  end  

  describe "#find_doc" do
    let (:klass) {@record.class}
    let (:value) {"old_title"}

    it "should use the solr field name and supplied values" do
      relation = double()
      relation.stub("first")
      klass.should_receive("where").once.with(solr_field => value).and_return(relation)
      validator.find_doc(klass, value)
    end
    it "should return one record when present" do
      doc = double(pid: "avalon:1")
      relation = double()
      relation.stub("first").and_return(doc)
      klass.stub("where").and_return(relation)
      validator.find_doc(klass, value).should be_an_instance_of klass
    end
    it "should return nil when not present" do
      relation = double()
      relation.stub("first").and_return(nil)
      klass.stub("where").and_return(relation)
      validator.find_doc(klass, value).should be_nil
    end
  end
end
