module FedoraMigrate
  class ReassignIdTargetConstructor < TargetConstructor
    def build
      raise FedoraMigrate::Errors::MigrationError, "No qualified targets found in #{source.pid}" if target.nil?
      target.new
    end
  end
end
