 require 'spec_helper'

 describe Unit do
   before(:all) do
     @manager = FactoryGirl.create('content_provider')
     @collection = Collection.create(name: "Herman B. Wells Collection")
     @unit = Unit.create(name: "University archives")
     @unit.managers = [@manager]
     @unit.collections = [@collection]
   end

   after(:all) do
     @manager.delete
     @unit.delete
     @collection.delete
   end

   it {should validate_presence_of(:name)}
   it {should validate_uniqueness_of(:name)}

   it "should be titled" do
     @unit.name.should == "University archives"
   end

   it "should have created_at defined" do
     @unit.created_at.should == DateTime.parse(@unit.create_date)
   end

   it "should have one manager" do
     @unit.managers.should == [@manager]
   end

   it "should have one collection" do
     @unit.collections.should == [@collection]
   end
   
   it "should solrize important information" do
     map = Solrizer::FieldMapper::Default.new
     @unit.to_solr[ map.solr_name(:name, :string, :searchable).to_sym ].should == "University archives"
     @unit.to_solr[ map.solr_name(:collection_count, :integer, :sortable).to_sym ].should == 1
   end 
 end
