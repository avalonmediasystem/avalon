class SpeedyAF::Base
  def respond_to_missing?(sym, _include_private = false)
    @attrs.key?(sym) ||
      model.respond_to?(:reflections) && model.reflections[sym].present? ||
      model.instance_methods.include?(sym)
  end
end
