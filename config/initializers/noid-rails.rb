require 'noid-rails'

Noid::Rails.configure do |config|
  config.minter_class = Noid::Rails::Minter::Db

  config.identifier_in_use = lambda do |id|
    ActiveFedora::Base.exists?(id) || ActiveFedora::Base.gone?(id)
  end
end
