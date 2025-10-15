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

      def to_solr
        super.tap do |solr_doc|
          solr_doc["title_uniq_si"] = title.downcase.gsub(/\s+/,'') if title.present?
        end
      end
    end
  end
  after(:all) { Object.send(:remove_const, :Foo) }

  let(:field) { 'title' }
  let(:solr_field) { "title_uniq_si" }
  let(:validator) { UniquenessValidator.new({ :attributes => [field], :solr_name => solr_field }) }
  let(:record) { Foo.new(title: title) }
  let(:title) { 'new_title' }

  it "should raise an exception if solr_name option is missing" do
     expect { UniquenessValidator.new({ attributes: [:title] }) }.to raise_error ArgumentError
  end

  it "should not return errors when field is unique" do
    expect(record).not_to receive('errors')
    validator.validate_each(record, field, record.attributes[field])
  end

  it "should not return errors when field is unique but record is the same" do
    record.save!
    expect(record.errors).not_to receive('add')
    validator.validate_each(record, field, record.attributes[field])
  end

  it "should return errors when field is not unique" do
    Foo.create(id: 'different-id', title: 'new_title')
    validator.validate_each(record, field, record.attributes[field])
    expect(record.errors).to_not be_empty
  end
end
