require 'spec_helper'

describe Avalon::AccessControls::VirtualGroups do

  before do
    class Foo < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
      include Avalon::AccessControls::VirtualGroups
    end
  end

  subject { Foo.new }

  describe 'virtual groups' do
    let!(:local_groups) {[FactoryGirl.create(:group).name, FactoryGirl.create(:group).name]}
    let(:virtual_groups) {["vgroup1", "vgroup2"]}
    before(:each) do
      subject.read_groups = local_groups + virtual_groups
    end

    describe '#local_group_exceptions' do
      it 'should have only local groups' do
        expect(subject.local_read_groups).to eq(local_groups)
      end
    end

    describe '#virtual_group_exceptions' do
      it 'should have only non-local groups' do
        expect(subject.virtual_read_groups).to eq(virtual_groups)
      end
    end
  end
end
