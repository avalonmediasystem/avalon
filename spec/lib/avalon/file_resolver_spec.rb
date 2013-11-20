require 'avalon/file_resolver'

describe Avalon::FileResolver do
  let(:resolver){ Avalon::FileResolver.new }
  describe "#path_to" do
    it 'returns umodified path when string already has a schema' do
      resolver.path_to('http://example.com').should == 'http://example.com'
    end
    it 'returns path with schema' do
      resolver.stub(:mount_map).and_return({'/Volumes/dropbox/'=> 'smb://example.edu/dropbox'})
      resolver.path_to('/storage/master_files/').should == 'file:///storage/master_files/'
    end
  end

  describe "#mount_map" do
    it 'returns a formatted mount' do
      resolver.stub(:overrides).and_return({})
      resolver.instance_variable_set(:@mounts, ['//adam@example.edu/dropbox on /Volumes/dropbox (smbfs, nodev, nosuid, mounted by adam)'])
      resolver.mount_map.should == {'/Volumes/dropbox/'=>'smb://example.edu/dropbox'}
    end
  end
end