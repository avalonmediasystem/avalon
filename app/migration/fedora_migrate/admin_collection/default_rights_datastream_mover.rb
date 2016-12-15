module FedoraMigrate
  module AdminCollection
    class DefaultRightsDatastreamMover < PermissionsMover
      def migrate
        [:read_groups, :read_users].each do |permission|
          next unless target.respond_to?("default_" + permission.to_s + "=")
          report << "default_#{permission} = #{send(permission)}"
          target.send("default_" + permission.to_s + "=", send(permission))
        end
        target.default_hidden = discover_groups.include?("nobody") if target.respond_to?("default_hidden=")
        report << "default_hidden = #{target.default_hidden}"
        # save
        # super
        report
      end
    end
  end
end
