require 'rails_helper'

describe 'About page routes', type: :routing do
  context 'as an administrator' do
  end

  context 'as an end-user' do
    before do
      allow_any_instance_of(Avalon::Routing::CanConstraint).to receive(:matches?).and_return(false)
    end

    it "does route to /about/health.yaml" do
      expect(:get => "/about/health.yaml").to be_routable
    end

    it "does not route to /about" do
      expect(:get => "/about/health").not_to be_routable
    end

    it "does not route to /about/health.*" do
      expect(:get => "/about/health.html").not_to be_routable
    end
  end 
end
