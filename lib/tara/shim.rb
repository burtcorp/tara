# encoding: utf-8

module Tara
  # @private
  class Shim
    def initialize(dirpath, name)
      @dirpath = dirpath
      @name = name
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
        exec "$SELF_DIR/lib/ruby/bin/ruby" -rbundler/setup "$SELF_DIR/#{@dirpath}/#{@name}" "$@"
      EOH
    end
  end
end
