require 'noid-rails'

Noid::Rails.configure do |config|
  config.minter_class = Noid::Rails::Minter::Db
end
