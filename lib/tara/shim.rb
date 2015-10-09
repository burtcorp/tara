# encoding: utf-8

module Tara
  # @private
  class Shim
    def initialize(command)
      @command = command
    end

    def write(io)
      io.puts(script_template)
    end

    private

    def script_template
      <<-EOH.gsub(/^\s+/, '')
        #!/bin/bash
        set -e
        SELF_DIR=$(dirname "$0")
        export BUNDLE_GEMFILE="$SELF_DIR/lib/vendor/Gemfile"
        unset BUNDLE_IGNORE_CONFIG
        exec "$SELF_DIR/lib/ruby/bin/ruby" -rbundler/setup #{@command}
      EOH
    end
  end

  # @private
  class ExecShim < Shim
    def initialize(dirpath, name)
      super(%("$SELF_DIR/#{dirpath}/#{name}" "$@"))
    end
  end

  # @private
  class GemShim < Shim
    def initialize(gem_name, exec_name)
     super(%(-e "load Gem.bin_path('#{gem_name}', '#{exec_name}')" -- "$@"))
    end
  end
end
