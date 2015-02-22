# encoding: utf-8

require 'rbconfig'


module DetectOS
  def detect_target
    @os ||= begin
      case (host_os = RbConfig::CONFIG['host_os'])
      when /darwin|mac os/
        'osx'
      when /linux/
        case RbConfig::CONFIG['arch']
        when /x86_64/
          'linux-x86_64'
        else
          'linux-x86'
        end
      else
        raise %(Unknown os: #{host_os.inspect})
      end
    end
  end
end

RSpec.configure do |config|
  config.include(DetectOS)
end
