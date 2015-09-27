# encoding: utf-8

module Tara
  # @private
  class Shell
    def self.exec(command)
      output = %x(#{command})
      $stderr.puts(%(#{command}: #{output})) if ENV['TARA_DEBUG']
      unless $?.success?
        raise ExecError, %(Command `#{command}` failed with output: #{output})
      end
      output
    rescue Errno::ENOENT => e
      raise ExecError, %(Command `#{command}` failed with output: #{e.message})
    end

    def self.exec_with_env(command, env)
      self.exec(env.map { |k, v| [k, v].join('=') }.join(' ') << ' ' << command)
    end
  end
end
