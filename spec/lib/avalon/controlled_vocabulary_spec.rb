require 'spec_helper'
require 'avalon/controlled_vocabulary'

describe Avalon::ControlledVocabulary do
  before do
    File.stub(:read).and_return { '' }
    File.stub(:file?).and_return true
  end

  describe '#vocabulary' do 
    it 'reads the file directly from disk' do
      File.should_receive(:read).twice
      Avalon::ControlledVocabulary.vocabulary
      Avalon::ControlledVocabulary.vocabulary
    end

    it 'returns an empty hash when yaml file is empty' do
      Avalon::ControlledVocabulary.vocabulary.should eql({})
    end
  end

  describe '#find_by_name' do
    before do
      Avalon::ControlledVocabulary.stub(:vocabulary).and_return({ units: ['Archives'] })
    end

    it 'finds a vocabulary by name' do
      Avalon::ControlledVocabulary.find_by_name('units').should eql ['Archives']
    end

    it 'finds a vocabulary by symbol' do
      Avalon::ControlledVocabulary.find_by_name(:units).should eql ['Archives']
    end
  end

end