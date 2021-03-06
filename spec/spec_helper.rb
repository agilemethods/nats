
$:.unshift('./lib')
require 'nats/client'

def timeout_nats_on_failure(to=0.25)
  EM.add_timer(to) { NATS.stop }
end

class NatsServerControl

  attr_reader :was_running
  alias :was_running? :was_running

  class << self
    def kill_autostart_server
      pid ||= File.read(NATS::AUTOSTART_PID_FILE).chomp.to_i
      %x[kill -9 #{pid}] if pid
      %x[rm #{NATS::AUTOSTART_PID_FILE}]
      %x[rm #{NATS::AUTOSTART_LOG_FILE}]
    end
  end

  def initialize(uri="nats://localhost:4222", pid_file='/tmp/test-nats.pid')
    @uri = URI.parse(uri)
    @pid_file = pid_file
  end

  def server_pid
    @pid ||= File.read(@pid_file).chomp.to_i
  end

  def server_mem_mb
    server_status = %x[ps axo pid=,rss= | grep #{server_pid}]
    parts = server_status.lstrip.split(/\s+/)
    rss = (parts[1].to_i)/1024
  end

  def start_server

    if NATS.server_running? @uri
      @was_running = true
      return
    end

    # This should work but is sketchy and slow under jruby, so use direct
    # %x[ruby -S bundle exec nats-server -p #{@uri.port} -P #{@pid_file} -d 2> /dev/null]
    server = File.expand_path(File.join(__FILE__, "../../lib/nats/server.rb"))
    # daemonize really doesn't work on jruby, so should run servers manually to test on jruby
    args = "-p #{@uri.port} -P #{@pid_file} -d"
    args += " --user #{@uri.user}" if @uri.user
    args += " --pass #{@uri.password}" if @uri.password
    %x[ruby #{server} #{args} 2> /dev/null]
    NATS.wait_for_server(@uri, 10) #jruby can be slow on startup
  end

  def kill_server
    if File.exists? @pid_file
      %x[kill -9 #{server_pid} 2> /dev/null]
      %x[rm #{@pid_file} 2> /dev/null]
      %x[rm #{NATS::AUTOSTART_LOG_FILE} 2> /dev/null]
    end
  end
end
