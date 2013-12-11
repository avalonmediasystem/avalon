require 'spec_helper'
require 'avalon/sanitizer'

describe Avalon::Sanitizer do
  describe '#sanitize' do
    it 'replaces blacklisted characters' do
      Avalon::Sanitizer.sanitize('abcdefg&',['&','_']).should == 'abcdefg_'
    end

    it 'replaces multiple blacklisted characters' do
      Avalon::Sanitizer.sanitize('avalon*media&system',['*&','__']).should == 'avalon_media_system'
    end

    it 'does not modify a string without any blacklisted characters' do
      Avalon::Sanitizer.sanitize('avalon_media_system',['*&','__']).should == 'avalon_media_system'
    end
  end
end
