# encoding: utf-8

module Tara
  class Shell
    def self.exec(command)
      output = %x(#{command})
      unless $?.success?
        raise ExecError, %(Command `#{command}` failed with output: #{output})
      end
      output
    end
  end
end
