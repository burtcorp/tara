# encoding: utf-8

module Tara
  class Executable
    def initialize(name)
      @name = name
    end

    def write(io)
      io.puts(script(@name))
    end

    private

    def script(name)
      <<-EOH.gsub(/^\s+/, '')
        #!/bin/bash
        set -e
        SELF_DIR=$(dirname "$0")
        export BUNDLE_GEMFILE="$SELF_DIR/lib/vendor/Gemfile"
        unset BUNDLE_IGNORE_CONFIG
        exec "$SELF_DIR/lib/ruby/bin/ruby" -rbundler/setup "$SELF_DIR/bin/#{name}" "$@"
      EOH
    end
  end
end
