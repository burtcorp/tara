# encoding: utf-8

require 'optparse'


module Tara
  # @private
  class Cli
    def initialize(argv=ARGV, io=$stderr)
      @argv = argv
      @io = io
    end

    def run
      Archive.new(parse_argv).create
      0
    rescue => e
      @io.puts(%(Error during packaging: #{e.message} (#{e.class})))
      1
    end

    private

    def parse_argv(options={})
      parser = OptionParser.new do |opts|
        opts.on('--app-name NAME', 'Name of the app') do |app_name|
          options[:app_name] = app_name
        end

        opts.on('--app-dir APP_DIR', 'Root directory of the app') do |app_dir|
          options[:app_dir] = app_dir
        end

        opts.on('--download-dir DOWNLOAD_DIR', 'Where to store Traveling Ruby archives') do |download_dir|
          options[:download_dir] = download_dir
        end

        opts.on('--target TARGET', 'Target platform for archive') do |target|
          options[:target] = target
        end
      end
      parser.parse(@argv)
      options
    end
  end
end
