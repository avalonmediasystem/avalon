# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

describe "UniquenessValidator" do

  before(:all) do
    class Foo < ActiveFedora::Base
      property :title, predicate: ::RDF::Vocab::DC.title, multiple: false
    end
  end
  after(:all) { Object.send(:remove_const, :Foo) }

  let(:solr_field) {"title_uniq_si"}
  let(:validator) {UniquenessValidator.new({:attributes => [:title], :solr_name => solr_field})}
  let(:record) {Foo.new}

  it "should raise an exception if solr_name option is missing" do
     expect{UniquenessValidator.new({attributes: [:title]})}.to raise_error ArgumentError
  end

  it "should not return errors when field is unique" do
    allow(validator).to receive("find_doc").and_return(nil)
    expect(record).not_to receive('errors')
    validator.validate_each(record, "title", "new_title")
  end

  it "should not return errors when field is unique but record is the same" do
    doc = double(id: record.id)
    allow(validator).to receive("find_doc").and_return(doc)
    expect(record.errors).not_to receive('add')
    validator.validate_each(record, "title", "new_title")
  end

  it "should return errors when field is not unique" do
    doc = double(id: 'different-id')
    allow(validator).to receive("find_doc").and_return(doc)
    # expect(record.errors).to receive('add')
    validator.validate_each(record, "title", "old_title")
    expect(record.errors).to_not be_empty
  end

  describe "#find_doc" do
    let (:klass) {record.class}
    let (:value) {"old_title"}

    it "should use the solr field name and supplied values" do
      relation = double()
      allow(relation).to receive("first")
      expect(klass).to receive(:where).once.with(solr_field => value).and_return(relation)
      validator.find_doc(klass, value)
    end
    it "should return one record when present" do
      doc = Foo.new
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
