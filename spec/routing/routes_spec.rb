require 'spec_helper'

describe "Routes" do
  describe "Collections" do
    it {expect(:get=> "/admin/collections").to route_to(controller: 'admin/collections', action: 'index')}
    it {expect(:get=> "/admin/collections/new").to route_to(controller: 'admin/collections', action: 'new')}
    it {expect(:get=> "/admin/collections/1").to route_to(controller: 'admin/collections', action: 'show', id: '1')}
    it {expect(:get=> "/admin/collections/1/edit").to route_to(controller: 'admin/collections', action: 'edit', id: '1')}
    it {expect(:post=> "/admin/collections").to route_to(controller: 'admin/collections', action: 'create')}
    it {expect(:put=> "/admin/collections/1").to route_to(controller: 'admin/collections', action: 'update', id:'1')}
    it {expect(:delete=> "/admin/collections/1").to route_to(controller: 'admin/collections', action: 'destroy', id:'1')}
  end
end
