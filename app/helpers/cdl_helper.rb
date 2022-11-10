module CdlHelper
  def lending_enabled?(context)
    context.respond_to?(:cdl_enabled) ? context.cdl_enabled : context&.default_enable_cdl
  end
end
