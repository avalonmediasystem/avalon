require 'spec_helper'
require 'hydrant/dropbox'


describe Hydrant::Dropbox do

  describe "#delete" do

    it 'returns true if the file is found' do
      File.stub(:delete).and_return true
      Hydrant::DropboxService.delete('some_file.mov')
    end

    it 'returns false if the file is not found' do
      Hydrant::DropboxService.delete('some_file.mov').should be_false
    end

  end

end