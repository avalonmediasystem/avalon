require 'spec_helper'
require 'cancan/matchers'

describe Collection do
  before(:each) do
    @manager = FactoryGirl.create(:content_provider)
    @collection = FactoryGirl.create(:collection, name: 'Herman B. Wells Collection', unit: "University Archives", description: "Collection about our 11th university president, 1938-1962", managers: [@manager])
  end

  after(:each) do
    @manager.destroy
    @collection.destroy
  end

  describe 'abilities' do

    subject{ ability }
    let(:ability){ Ability.new(user) }
    let(:user){ @collection.managers.first }

    context 'when unit manager' do
      it{ should be_able_to(:manage, @collection) }
    end
  end

  describe 'validations' do
    subject {@collection}
    let(:unit_names) {["University Archives", "Black Film Center/Archive"]}

    it {should validate_presence_of(:name)}
    it {should validate_uniqueness_of(:name)}
    it {should validate_presence_of(:unit)}
    it {should ensure_inclusion_of(:unit).in_array(unit_names)}

    its(:name) {should == "Herman B. Wells Collection"}
    its(:unit) {should == "University Archives"}
    its(:description) {should == "Collection about our 11th university president, 1938-1962"}
    its(:created_at) {should == DateTime.parse(@collection.create_date)}
    its(:managers) {should == [@manager]}

    its(:rightsMetadata) {should be_kind_of Hydra::Datastream::RightsMetadata}
    its(:defaultRights) {should be_kind_of Hydra::Datastream::InheritableRightsMetadata}
  end

  describe "#to_solr" do
    it "should solrize important information" do
     map = Solrizer::FieldMapper::Default.new
     @collection.to_solr[ map.solr_name(:name, :string, :searchable).to_sym ].should == "Herman B. Wells Collection"
    end
  end

  describe "#managers" do
    it "should return the intersection of edit_users and managers role" do
      collection = FactoryGirl.build(:collection)
      collection.edit_users = ["cjcolvar", "pdinh"]
      RoleControls.should_receive("users").with("managers").and_return(["cjcolvar", "atomical"])
      collection.managers.should == ["cjcolvar"]  #collection.edit_users & RoleControls.users("managers")
    end
  end
  describe "#editors" do
    it "should return the intersection of edit_users and editors role" do
      collection = FactoryGirl.build(:collection)
      collection.edit_users = ["cjcolvar", "pdinh"]
      RoleControls.should_receive("users").with("editors").and_return(["pdinh", "mbklein"])
      collection.editors.should == ["pdinh"]  #collection.edit_users & RoleControls.users("editors")
    end
  end
  describe "#depositors" do
    it "should return the intersection of default_edit_users and depositors role" do
      collection = FactoryGirl.build(:collection)
      collection.default_edit_users = ["cjcolvar", "pdinh"]
      RoleControls.should_receive("users").with("depositors").and_return(["pdinh", "mbklein"])
      collection.depositors.should == ["pdinh"]  #collection.default_edit_users & RoleControls.users("depositors")
    end
  end
end

