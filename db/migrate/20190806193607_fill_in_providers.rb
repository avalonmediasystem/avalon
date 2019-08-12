class FillInProviders < ActiveRecord::Migration[5.2]
  def change
    User.where('provider IS NULL').find_each do |user|
      identity = Identity.find_by(email: user.email) if user.email
      if identity
        user.update_attribute(:provider, 'identity')
      elsif user.uid.present?
        user.update_attribute(:provider, Avalon::Authentication::VisibleProviders.first[:provider])
      else
        user.update_attribute(:provider, 'local')
      end
    end
  end
end
