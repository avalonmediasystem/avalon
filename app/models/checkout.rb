class Checkout < ApplicationRecord
  belongs_to :user

  validates :user, :media_object_id, :checkout_time, :return_time, presence: true

  after_initialize :set_checkout_return_times!

  scope :active_for_media_object, ->(media_object_id) { where(media_object_id: media_object_id).where("return_time > now()") }
  scope :active_for_user, ->(user_id) { where(user_id: user_id).where("return_time > now()") }
  scope :returned_for_user, ->(user_id) { where(user_id: user_id).where("return_time < now()") }

  def media_object
    MediaObject.find(media_object_id)
  end

  private

  def set_checkout_return_times!
    self.checkout_time ||= DateTime.current
    self.return_time ||= checkout_time + duration
  end

  def duration
    duration = media_object.lending_period if media_object_id.present?
    duration ||= ActiveSupport::Duration.parse(Settings.controlled_digital_lending.default_lending_period)
    duration
  end
end
