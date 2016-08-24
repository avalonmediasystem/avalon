require 'securerandom'

class ApiToken < ActiveRecord::Base
  
  after_initialize :ensure_token
  
  def ensure_token
    self.token ||= SecureRandom.hex(64)
  end
  
end
