require 'active-fedora'

module Hydra::AccessControlsEnforcement
  def escape_filter(key, value)
    [key, escape_value(value)].join(':')
  end

  def escape_value(value)
    RSolr.solr_escape(value).gsub(/ /, '\ ')
  end
end
