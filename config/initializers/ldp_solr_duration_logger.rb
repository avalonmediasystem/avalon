# This module enables tracking the sum duration that LDP and solr requests take 
# and report it back alongside the view and DB times in the rails log for each request.

module AvalonInstrumentation
  extend ActiveSupport::Concern

  module ClassMethods
    def log_process_action(payload)
      messages, ldp_runtime, solr_runtime = super, payload[:ldp_runtime], payload[:solr_runtime]
      messages << ("LDP: %.1fms" % ldp_runtime.to_f) if ldp_runtime
      messages << ("Solr: %.1fms" % solr_runtime.to_f) if solr_runtime
      messages
    end
  end

  private
    attr_internal :ldp_runtime, :solr_runtime

    def process_action(action, *args)
      # We also need to reset the runtime before each action
      # because of queries in middleware or in cases we are streaming
      # and it won't be cleaned up by the method below.
      HttpLogSubscriber.reset_ldp_runtime
      HttpLogSubscriber.reset_solr_runtime
      super
    end

    def cleanup_view_runtime
      if logger && logger.info?
        ldp_rt_before_render = HttpLogSubscriber.reset_ldp_runtime
        solr_rt_before_render = HttpLogSubscriber.reset_solr_runtime
        self.ldp_runtime = (ldp_runtime || 0) + ldp_rt_before_render
        self.solr_runtime = (solr_runtime || 0) + solr_rt_before_render

        runtime = super

        ldp_rt_after_render = HttpLogSubscriber.reset_ldp_runtime
        solr_rt_after_render = HttpLogSubscriber.reset_solr_runtime
        self.ldp_runtime += ldp_rt_after_render
        self.solr_runtime += solr_rt_after_render
        runtime - ldp_rt_after_render - solr_rt_after_render
      else
        super
      end
    end

    def append_info_to_payload(payload)
      super
      payload[:ldp_runtime] = (self.ldp_runtime || 0) + HttpLogSubscriber.reset_ldp_runtime
      payload[:solr_runtime] = (self.solr_runtime || 0) + HttpLogSubscriber.reset_solr_runtime
    end

  class HttpLogSubscriber < ActiveSupport::LogSubscriber
    class_attribute :ldp_runtime, :solr_runtime
    self.ldp_runtime ||= 0
    self.solr_runtime ||= 0

    ActiveSupport::Notifications.subscribe('request.faraday') do |name, starts, ends, _, env|
      url = env[:url].to_s
      duration = (ends - starts) * 1000
      self.ldp_runtime += duration if url.start_with?(ActiveFedora.fedora.base_uri)
      self.solr_runtime += duration if url.start_with?(ActiveFedora.solr.options[:url])
    end

    def self.reset_ldp_runtime
      rt, self.ldp_runtime = self.ldp_runtime, 0
      rt
    end

    def self.reset_solr_runtime
      rt, self.solr_runtime = self.solr_runtime, 0
      rt
    end
  end
end

ActiveSupport.on_load(:action_controller) do
  ActionController::Base.include(AvalonInstrumentation)
end

# Enable Faraday instrumentation in all Faraday clients
module FaradayConnectionOptions
  def new_builder(block)
    super.tap do |builder|
      builder.request :instrumentation
    end
  end
end
Faraday::ConnectionOptions.prepend(FaradayConnectionOptions)
