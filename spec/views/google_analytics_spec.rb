require 'rails_helper'

describe "modules/_google_analytics.html.erb", type: :view do
  context "Google Analytics is configured" do
    before do
      Settings.google_analytics_tracking_id = "arandomid"
    end

    it 'includes GA code' do
      render
      expect(rendered).to have_selector(:css, "script[src='https://www.googletagmanager.com/gtag/js?id=arandomid']", visible: false)
    end
  end

  context "Google Analytics is not configured" do
    before do
      Settings.google_analytics_tracking_id = nil
    end

    it 'does not include GA code' do
      render
      expect(rendered).not_to have_selector(:css, "script[src='https://www.googletagmanager.com/gtag/js?id=arandomid']", visible: false)
    end
  end
end
