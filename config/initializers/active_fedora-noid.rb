require 'active_fedora/noid'

ActiveFedora::Noid.configure do |config|
  config.minter_class = ActiveFedora::Noid::Minter::Db
end
