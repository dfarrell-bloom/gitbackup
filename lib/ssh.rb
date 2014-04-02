
require 'net/ssh' 

class Net::SSH::Connection::Session
  class CommandFailed < StandardError
  end

  class CommandExecutionFailed < StandardError
  end

  def exec_st(command)
    exit_code,exit_signal = nil,nil
	stdout, stderr = "", ""
    self.open_channel do |channel|
	  # $stderr.puts "\033[0;1mExecuting command:\033[0;33m #{command}\033[0m"
      channel.exec(command) do |_, success|
        raise CommandExecutionFailed, "Command \"#{command}\" was unable to execute" unless success

        channel.on_data do |_,data|
          stdout << data
        end

        channel.on_extended_data do |_,_,data|
           stderr << data
        end

        channel.on_request("exit-status") do |_,data|
          exit_code = data.read_long
        end

        channel.on_request("exit-signal") do |_, data|
          exit_signal = data.read_long
        end
      end
    end
    self.loop
    {
	  stdout: stdout,
      stderr: stderr,
      exit_code: exit_code,
	  status: exit_code,
      exit_signal: exit_signal
    }
  end
end
