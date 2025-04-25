# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# to prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Only use a pidfile when requested
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

state_path ENV["PUMA_STATE_PATH"] if ENV["PUMA_STATE_PATH"]
activate_control_app

def start_puma_instrumentation
  require "prometheus_exporter"
  require "prometheus_exporter/instrumentation"

  if !PrometheusExporter::Instrumentation::Puma.started?
    PrometheusExporter::Instrumentation::Process.start(type: "puma_master")
    PrometheusExporter::Instrumentation::Puma.start
  end
end

after_worker_boot do
  start_puma_instrumentation
end

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
    PrometheusExporter::Instrumentation::ActiveRecord.start
  end

  PrometheusExporter::Instrumentation::Process.start(type: "puma_worker")
end

# Allow running instrumentation in single process mode
if !ENV["WEB_CONCURRANCY"]
  start_puma_instrumentation
end
