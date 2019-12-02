class SpeedyAF::Proxy::MasterFile < SpeedyAF::Base
  def encoder_class
    find_encoder_class(encoder_classname) || find_encoder_class(workflow_name.to_s.classify) || find_encoder_class((Settings.encoding.engine_adapter + "_encode").classify) || MasterFile.default_encoder_class || WatchedEncode
  end

  def find_encoder_class(klass_name)
    ActiveEncode::Base.descendants.find { |c| c.name == klass_name }
  end
end