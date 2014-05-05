# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
IcuWwwApp::Application.initialize!

# For Paperclip.
Paperclip.options[:command_path] = `which convert`.sub(/\/[^\/]+$/, "/")
