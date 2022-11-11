module CdlHelper
  def lending_enabled?(context)
    if Avalon::Configuration.controlled_digital_lending_enabled?
      context.respond_to?(:cdl_enabled?) ? context.cdl_enabled? : context&.cdl_enabled
    end
  end
end
