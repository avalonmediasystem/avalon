module ActiveFedora
  class UnsavedDigitalObject
    def assign_pid
    	pid_opts = {}
    	if ns = Avalon::Configuration.lookup('fedora.namespace')
    		pid_opts[:namespace] = ns
    	end
      @pid ||= Nokogiri::XML(ActiveFedora::Base.connection_for_pid(0).next_pid(pid_opts)).at_xpath('//*[local-name()="pid"]').text
    end
  end
end
