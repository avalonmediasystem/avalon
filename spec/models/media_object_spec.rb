require 'spec_helper'

describe MediaObject do
  describe "access" do
    it "should set access level to public" do
      @mediaobject = MediaObject.new
      @mediaobject.access = "public"
      @mediaobject.read_groups.should =~ ["public", "registered"]
    end
    it "should set access level to restricted" do
      @mediaobject = MediaObject.new
      @mediaobject.access = "restricted"
      @mediaobject.read_groups.should =~ ["registered"]
    end
    it "should set access level to private" do
      @mediaobject = MediaObject.new
      @mediaobject.access = "private"
      @mediaobject.read_groups.should =~ []
    end
  end
end
