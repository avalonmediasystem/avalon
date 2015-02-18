# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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
