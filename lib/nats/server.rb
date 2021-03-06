
require 'socket'
require 'fileutils'
require 'pp'

ep = File.expand_path(File.dirname(__FILE__))

require "#{ep}/ext/em"
require "#{ep}/ext/bytesize"
require "#{ep}/ext/json"
require "#{ep}/server/server"
require "#{ep}/server/sublist"
require "#{ep}/server/options"
require "#{ep}/server/const"
require "#{ep}/server/util"

# Do setup
NATSD::Server.setup(ARGV.dup)

# Event Loop
EM.run {
  log "Starting #{NATSD::APP_NAME} version #{NATSD::VERSION} on port #{NATSD::Server.port}"
  begin
    EM.set_descriptor_table_size(32768) # Requires Root privileges
    EventMachine::start_server(NATSD::Server.host, NATSD::Server.port, NATSD::Connection)
  rescue => e
    log "Could not start server on port #{NATSD::Server.port}"
    log_error
    exit(1)
  end
}
