require 'spec_helper'
describe Hydra::Datastream::InheritableRightsMetadata do
  it "should not index anything" do
    obj = ActiveFedora::Base.new
    datastream = Hydra::Datastream::NonIndexedRightsMetadata.new(obj.inner_object, nil)
    datastream.to_solr.should == {}
  end
end
