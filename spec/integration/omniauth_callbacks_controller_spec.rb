require 'spec_helper'

describe Users::OmniauthCallbacksController do

  context 'lti' do
    let(:lti_fixtures) { YAML.load(File.read(File.expand_path('../../config/lti_params.yml', __FILE__))) }
    let(:lti_config)   { lti_fixtures[:config]                               }
    let(:foo_hash)     { lti_fixtures[:foo]                                  }
    let(:foo_config)   { lti_config[foo_hash['tool_consumer_instance_guid']] }
    let(:user_uid)     { foo_hash[foo_config[:uid]]                          }
    let(:user_email)   { foo_hash[foo_config[:email]]                        }
    let(:course_id)    { foo_hash[foo_config[:context_id]]                   }
    let(:course_name)  { foo_hash[foo_config[:context_name]]                 }

    before :each do
      IMS::LTI::ToolProvider.any_instance.stub(:valid_request!) { true }
      @old_config = Devise.omniauth_configs[:lti].options[:consumers]
      Devise.omniauth_configs[:lti].options[:consumers] = Devise.omniauth_configs[:lti].strategy[:consumers] = lti_config
    end

    after :each do
      Devise.omniauth_configs[:lti].options[:consumers] = Devise.omniauth_configs[:lti].strategy[:consumers] = @old_config
    end

    it 'should create the user if necessary' do
      expect { post '/users/auth/lti/callback', foo_hash }.to change { User.all.count }
      new_user = User.last
      expect(new_user.username).to eq(user_uid)
      expect(new_user.email).to eq(user_email)
    end

    it 'should create the course if necessary' do
      expect { post '/users/auth/lti/callback', foo_hash }.to change { Course.all.count }
      new_course = Course.last
      expect(new_course.context_id).to eq(course_id)
      expect(new_course.title).to eq(course_name)
    end

    it 'should use an existing user if possible' do
      FactoryGirl.build(:user, username: user_uid, email: user_email).save
      expect { post '/users/auth/lti/callback', foo_hash }.not_to change { User.all.count }
    end

    it 'should use an existing course if possible' do
      FactoryGirl.build(:course, context_id: course_id, label: course_name).save
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
