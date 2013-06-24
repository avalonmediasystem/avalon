require 'spec_helper'

describe "UniquenessValidator" do

  let(:solr_field) {"title_t"}
  let(:validator) {UniquenessValidator.new({:attributes => {}, :solr_name => solr_field})}

  before(:each) do
    @record = stub(pid:"avalon:1")
    @record.stub("errors").and_return([])
  end

  it "should raise an exception if solr_name option is missing" do
     expect{UniquenessValidator.new({attributes: {}})}.to raise_error ArgumentError
  end

  it "should not return errors when field is unique" do
    validator.stub("find_doc").and_return(nil)
    @record.should_not_receive('errors')  
    validator.validate_each(@record, "title", "new_title")
  end

  it "should not return errors when field is unique but record is the same" do
    doc = stub(pid: "avalon:1")
    validator.stub("find_doc").and_return(doc)
    @record.should_not_receive('errors')
    validator.validate_each(@record, "title", "new_title")
  end

  it "should return erros when field is not unique" do
    doc = stub(pid: "avalon:2")
    validator.stub("find_doc").and_return(doc)
    @record.errors.should_receive('add')
    validator.validate_each(@record, "title", "old_title")
  end  

  describe "#find_doc" do
    let (:klass) {@record.class}
    let (:value) {"old_title"}

    it "should use the solr field name and supplied values" do
      relation = stub()
      relation.stub("first")
      klass.should_receive("where").once.with(solr_field => value).and_return(relation)
      validator.find_doc(klass, value)
    end
    it "should return one record when present" do
      doc = stub(pid: "avalon:1")
      relation = stub()
      relation.stub("first").and_return(doc)
      klass.stub("where").and_return(relation)
      validator.find_doc(klass, value).should be_an_instance_of klass
    end
    it "should return nil when not present" do
      relation = stub()
      relation.stub("first").and_return(nil)
      klass.stub("where").and_return(relation)
      validator.find_doc(klass, value).should be_nil
    end
  end
end

