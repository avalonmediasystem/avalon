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

describe UrlDatastream do
  let(:test_object) { obj = ActiveFedora::Base.new ; obj.save ; obj      }
  subject           { UrlDatastream.new(test_object.inner_object, 'foo') }

  after :each do
    test_object.destroy
  end

  describe "uninitialized" do
    it "should have default properties" do 
      expect(subject.mimeType).to eq('text/url')
      expect(subject.controlGroup).to eq('M')
      expect(subject.location).to be_nil
    end
  end

  describe "validation" do
    ['http://example.edu/foo/bar/baz.jpg',
     'file:///path/to/foo/bar/baz.jpg',
     'nfs://nfs.example.edu/share/foo/bar/baz.jpg',
     'smb://samba.example.edu/share/foo/bar/baz.jpg'].each do |loc|
      it "should accept #{loc}" do
        subject.location = loc
        expect(subject.location).to eq(loc)
      end
    end

    it "should require a valid URL" do
      expect { subject.location = 'blah blah blah' }.to raise_error(URI::InvalidURIError)
    end
  end

  describe "initialized" do
    before :each do
      subject.location = 'file:///path/to/foo/bar/baz.jpg'
      test_object.save
    end

    it "should be initialized" do
      expect(subject.location).to eq('file:///path/to/foo/bar/baz.jpg')
    end

    it "should be blankable" do
      subject.location = ''
      expect(subject.location).to be_empty
    end

    it "should be nillable" do
      subject.location = nil
      expect(subject.location).to be_nil
    end
  end
end
