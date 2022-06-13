class Checkout < ApplicationRecord
  belongs_to :user

  validates :user, :media_object_id, :checkout_time, :return_time, presence: true

  scope :active_for_media_object, ->(media_object_id) { where(media_object_id: media_object_id).where("return_time > now()") }
  scope :active_for_user, ->(user_id) { where(user_id: user_id).where("return_time > now()") }

  def media_object
    MediaObject.find(media_object_id)
  end
end
