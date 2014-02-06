require 'spec_helper'

describe Users::OmniauthCallbacksController do
  let(:lti_fixtures) { YAML.load(File.read(File.expand_path('../../fixtures/lti_params.yml', __FILE__))) }
  let(:lti_config)   { lti_fixtures[:config] }

  before :each do
    request.env["devise.mapping"] = Devise.mappings[:user]
    tp = double(IMS::LTI::ToolProvider, :valid_request! => true)
    IMS::LTI::ToolProvider.stub(:new).and_return(tp)
    @old_config = Devise.omniauth_configs[:lti].options[:consumers]
    Devise.omniauth_configs[:lti].options[:consumers] = Devise.omniauth_configs[:lti].strategy[:consumers] = lti_config
  end

  after :each do
    Devise.omniauth_configs[:lti].options[:consumers] = Devise.omniauth_configs[:lti].strategy[:consumers] = @old_config
  end

  context 'foo' do
    let(:foo) { lti_fixtures[:foo] }

    it 'should create the user if necessary' do
      expect(post '/users/auth/lti/callback', foo).to change { User.all.count }
    end

    it 'should create the course if necessary' do
      expect { post '/users/auth/lti/callback', foo }.to change { Course.all.count }
    end

    it 'should use an existing user if possible' do
      existing_user = FactoryGirl.build(:user, username: foo[:lis_person_sourcedid], email: foo[:lis_person_contact_email_primary])
      expect { post '/users/auth/lti/callback', foo }.not_to change { User.all.count }
    end

    it 'should use an existing course if possible' do
      existing_course = FactoryGirl.build(:course, guid: foo[:context_id], label: foo[:context_title])
      expect { post '/users/auth/lti/callback', foo }.not_to change { Course.all.count }
    end

    it "should has virtual_groups if logs in as LTI" do
      expect(subject.current_user.virtual_groups).not_to be_empty
    end

    it "should not be able to share if logged in as LTI" do
      expect(Ability.new subject.current_user).not_to be_able_to :share, MediaObject
    end
  end
end
