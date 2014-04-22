require 'spec_helper'

describe VersionableModel do
  before :each do
    class VersionableTest < ActiveFedora::Base
      include VersionableModel

      has_model_version 'foo'
    end
  end

  after :each do
    Object.send(:remove_const, :VersionableTest)
  end

  it "class should know its version" do
    expect(VersionableTest.model_version).to eq('foo')
  end

  context 'object versioning' do
    subject { VersionableTest.new }

    it "should set its version" do
      subject.current_version = 'bar'
      expect(subject.current_version).to eq('bar')
    end

    it "should auto-save with the right version" do
      subject.current_version = 'bar'
      subject.save
      expect(subject.current_version).to eq('foo')
      expect(VersionableTest.find(subject.pid).current_version).to eq('foo')
    end

    it "should save as an explicit version" do
      subject.current_version = 'bar'
      subject.save_as_version('baz')
      expect(subject.current_version).to eq('baz')
      expect(VersionableTest.find(subject.pid).current_version).to eq('baz')
    end
  end
end
