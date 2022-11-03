module CdlHelper
  def collection_lending_enabled?(context)
    context.is_a?(MediaObject) ? context.cdl_enabled : context&.default_enable_cdl
  end
end
