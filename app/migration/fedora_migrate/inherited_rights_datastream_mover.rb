module FedoraMigrate
  class InheritedRightsDatastreamMover < PermissionsMover
    def migrate
      FedoraMigrate::Permissions.instance_methods.each do |permission|
        next unless target.respond_to?("inherited_" + permission.to_s + "=")
        report << "inherited_#{permission} = #{send(permission)}"
        target.send("inherited_" + permission.to_s + "=", send(permission))
      end
      # save
      # super
      report
    end
  end
end
