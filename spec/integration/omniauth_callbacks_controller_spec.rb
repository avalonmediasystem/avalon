require 'spec_helper'

describe Users::OmniauthCallbacksController do
  let(:lti_fixtures) { YAML.load(File.read(File.expand_path('../../fixtures/lti_params.yml', __FILE__))) }
  let(:lti_config)   { lti_fixtures[:config] }

  before :each do
#    request.env["devise.mapping"] = Devise.mappings[:user]
    IMS::LTI::ToolProvider.any_instance.stub(:valid_request!) { true }
    @old_config = Devise.omniauth_configs[:lti].options[:consumers]
    Devise.omniauth_configs[:lti].options[:consumers] = Devise.omniauth_configs[:lti].strategy[:consumers] = lti_config
  end

  after :each do
    Devise.omniauth_configs[:lti].options[:consumers] = Devise.omniauth_configs[:lti].strategy[:consumers] = @old_config
  end

  context 'foo' do
    let(:foo_hash) { OmniAuth::AuthHash.new(lti_fixtures[:foo]) }
    #let(:raw)      { foo_hash.extra.raw_info }
    
#    before :each do
#      request.env["omniauth.auth"] = foo_hash
#    end

    it 'should create the user if necessary' do
      expect { post '/users/auth/lti/callback', foo_hash }.to change { User.all.count }
    end

    it 'should create the course if necessary' do
      expect { post '/users/auth/lti/callback', foo_hash }.to change { Course.all.count }
    end

    it 'should use an existing user if possible' do
      u = FactoryGirl.build(:user, username: foo_hash[:lis_person_sourcedid], email: foo_hash[:lis_person_contact_email_primary])
      u.save
      expect { post '/users/auth/lti/callback', foo_hash }.not_to change { User.all.count }
    end

    it 'should use an existing course if possible' do
      FactoryGirl.build(:course, guid: foo_hash[:context_id], label: foo_hash[:context_title]).save
      expect { post '/users/auth/lti/callback', foo_hash }.not_to change { Course.all.count }
    end

    it "should have virtual_groups" do
      pending
      expect(subject.user_session[:virtual_groups]).not_to be_empty
    end

    it "should not be a full login" do
      pending
      expect(subject.user_session[:full_login]).to be_false
    end
  end
end
