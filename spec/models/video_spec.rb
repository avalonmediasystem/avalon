require 'spec_helper'

describe Video do
  describe "access" do
    it "should set access level to public" do
      @video = Video.new
      @video.access = "public"
      @video.read_groups.should =~ ["public", "registered"]
    end
    it "should set access level to restricted" do
      @video = Video.new
      @video.access = "restricted"
      @video.read_groups.should =~ ["registered"]
    end
    it "should set access level to private" do
      @video = Video.new
      @video.access = "private"
      @video.read_groups.should =~ []
    end
  end
end
