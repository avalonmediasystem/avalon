require 'spec_helper'

describe Hydra::AccessControls::Visibility do

  before do
    class Foo < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
      include Hydra::AccessControls::Visibility
    end
  end

  subject { Foo.new }

  describe "#visibility=" do
    it "should raise error on invalid visibility value" do
      expect {subject.visibility="blahalklkadsjfl"}.to raise_error(ArgumentError)
    end
  end

  describe "#visibility" do
    it "should return public visibility if public group is present" do
      subject.read_groups = [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    it "should return authenticated visibility if authenticated group is present" do
subject.read_groups = [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
      expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED

    end
    it "should default to private visibility" do
      expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
   
    end
  end
end
