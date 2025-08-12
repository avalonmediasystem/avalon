# Having `rack-mini-profiler` in the Gemfile will automatically load it and use it in non-production environments.
# This initializer will respect `AVALON_PROFILING`` in docker-compose.yml and turn on/off profiling accordingly.
Rack::MiniProfiler.config.authorization_mode = :allow_authorized
