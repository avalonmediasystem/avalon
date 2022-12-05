# frozen_string_literal: true
# Copied from Hyrax: spec/support/features/session_helpers.rb
module Features
  module SessionHelpers
    def sign_in(who = :user)
      user = who.is_a?(User) ? who : FactoryBot.build(:user).tap(&:save!)
      visit '/users/sign_in'
      within('div.omniauth-form form') do
        fill_in 'Login', with: user.email
        fill_in 'Password', with: user.password
        click_on 'Connect'
      end
    end
  end
end
