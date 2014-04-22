require 'spec_helper'

describe Avalon::AccessControls::Hidden do

  before do
    class Foo < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
      include Avalon::AccessControls::Hidden
    end
  end

  subject { Foo.new }

  describe "hidden" do
    it "should default to discoverable" do
      subject.hidden?.should be_false
      subject.to_solr["hidden_bsi"].should be_false
    end

    it "should set hidden?" do
      subject.hidden = true
      subject.hidden?.should be_true
      subject.to_solr["hidden_bsi"].should be_true
    end
  end
end
