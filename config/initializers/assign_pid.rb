module ActiveFedora
  class UnsavedDigitalObject
    def assign_pid
   	pid_opts = {}
    	if ns = Avalon::Configuration.lookup('fedora.namespace')
    		pid_opts[:namespace] = ns
    	end
      @pid ||= ActiveFedora::Base.connection_for_pid('0').mint pid_opts
    end
  end
end
