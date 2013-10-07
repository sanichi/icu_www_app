# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
IcuWwwApp::Application.initialize!

# Deal with connecting to Redis in forked worker processes.
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      # We're in smart spawning mode.
      Translation.reconnect("worker process")
    else
      # We're in conservative spawning mode. We don't need to do anything.
    end
  end
end
