module ActiveFedora
  class UnsavedDigitalObject
    def assign_pid
    	pid_opts = {}
    	if Avalon::Configuration['fedora'] && ns = Avalon::Configuration['fedora']['namespace']
    		pid_opts[:namespace] = ns
    	end
      @pid ||= Nokogiri::XML(ActiveFedora::Base.connection_for_pid(0).next_pid(pid_opts)).at_xpath('//xmlns:pid').text
    end
  end
end