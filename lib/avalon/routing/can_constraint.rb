module Avalon::Routing
  class CanConstraint
    def initialize(action, thing, scope=nil)
      @action = action
      @thing = thing
      @scope = scope
    end
    def matches?(request)
      warden = request.env['warden']
      warden.authenticate? && Ability.new(warden.user(@scope), warden.session(@scope)).can?(@action, @thing)
    end
  end
end
