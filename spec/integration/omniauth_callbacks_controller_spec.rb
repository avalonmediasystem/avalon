require 'spec_helper'

describe Users::OmniauthCallbacksController do
  let(:lti_fixtures) { YAML.load(File.read(File.expand_path('../../fixtures/lti_params.yml', __FILE__))) }
  let(:lti_config)   { lti_fixtures[:config] }

  before :each do
    IMS::LTI::ToolProvider.any_instance.stub(:valid_request!) { true }
    @old_config = Devise.omniauth_configs[:lti].options[:consumers]
    Devise.omniauth_configs[:lti].options[:consumers] = Devise.omniauth_configs[:lti].strategy[:consumers] = lti_config
  end

  after :each do
    Devise.omniauth_configs[:lti].options[:consumers] = Devise.omniauth_configs[:lti].strategy[:consumers] = @old_config
  end

  context 'foo' do
    let(:foo_hash) { OmniAuth::AuthHash.new(lti_fixtures[:foo]) }

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
      FactoryGirl.build(:course, context_id: foo_hash[:context_id], label: foo_hash[:context_title]).save
      expect { post '/users/auth/lti/callback', foo_hash }.not_to change { Course.all.count }
    end

    context 'user session' do
      subject { Hash.new }

      before :each do
        Users::OmniauthCallbacksController.any_instance.stub(:user_session) { subject }
        post '/users/auth/lti/callback', foo_hash
      end

      it "should have virtual_groups" do
        expect(subject[:virtual_groups]).not_to be_empty
      end

      it "should not be a full login" do
        expect(subject[:full_login]).to be_false
      end
    end
  end
end
