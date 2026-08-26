class Admin::ApplicationSetting < ApplicationRecord
  validates :singleton_guard, inclusion: [0]

  def self.instance
    where(singleton_guard: 0).first_or_create!
  end
end
