require 'rails_helper.rb'

describe 'AboutPage' do
  describe 'routing' do
    context 'as an administrator' do
      before do
        allow_any_instance_of(Avalon::Routing::CanConstraint).to receive(:matches?).and_return(true)
      end
      it "can access /about" do
        get about_page_path
        expect(response).to have_http_status(200)
      end
      it "can access /about/health" do
        get about_page.health_path
        expect(response).to have_http_status(200)
      end
      it "can access /about/health.yaml" do
        get '/about/health.yaml'
        expect(response).to have_http_status(200)
      end
    end

    context 'as an end-user' do
      before do
        allow_any_instance_of(Avalon::Routing::CanConstraint).to receive(:matches?).and_return(false)
      end
      it "redirects to root when unauthorized request to /about" do
        get about_page_path
        expect(response).to have_http_status(301)
      end
      it "redirects to root when unauthorized request to /about/health" do
        get about_page.health_path
        expect(response).to have_http_status(301)
      end
      it "can access /about/health.yaml" do
        get '/about/health.yaml'
        expect(response).to have_http_status(200)
      end
    end
  end
end
