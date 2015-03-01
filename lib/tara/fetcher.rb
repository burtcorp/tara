# encoding: utf-8

require 'net/http'


module Tara
  class Fetcher
    def initialize(download_dir, target, tr_version, options={})
      @download_dir = download_dir
      @target = target
      @tr_version = tr_version
      @ruby_version = options[:ruby_version] || RUBY_VERSION
      @release_url = options[:tr_release_url] || 'http://d6r77u77i8pq3.cloudfront.net/releases'
      @shell = options[:shell] || Shell
    end

    def setup
      FileUtils.mkdir_p(@download_dir)
      self
    end

    def fetch_ruby
      local_uri = %(#{@download_dir}/ruby-#{@tr_version}-#{@ruby_version}-#{@target}.tar.gz)
      fetch(ruby_remote_uri, local_uri)
    end

    def fetch_native_gem(name, version)
      remote_uri = native_gem_remote_uri(name, version)
      local_uri = %(#{@download_dir}/#{name}-#{version}-#{@tr_version}-#{@ruby_version}-#{@target}.tar.gz)
      fetch(remote_uri, local_uri)
    end

    private

    def ruby_remote_uri
      @ruby_remote_uri ||= [@release_url, %(traveling-ruby-#{@tr_version}-#{@ruby_version}-#{@target}.tar.gz)].join('/')
    end

    def native_gem_remote_uri(name, version)
      [@release_url, %(traveling-ruby-gems-#{@tr_version}-#{@ruby_version}-#{@target}/#{name}-#{version}.tar.gz)].join('/')
    end

    def fetch(remote_uri, local_uri, limit=10)
      unless File.exist?(local_uri)
        uri = URI(remote_uri)
        Net::HTTP.start(uri.host, uri.port) do |http|
          http.request(Net::HTTP::Get.new(uri)) do |response|
            case response
            when Net::HTTPSuccess
              File.open(local_uri, 'w') do |f|
                response.read_body do |chunk|
                  f.write(chunk)
                end
              end
            when Net::HTTPRedirection
              if limit > 0
                fetch(response['location'], local_uri, limit - 1)
              else
                raise TooManyRedirectsError, %(Exhausted redirect limit, ended up at #{remote_uri})
              end
            when Net::HTTPNotFound
              raise NotFoundError, %(#{remote_uri} doesn't exist)
            else
              raise UnknownResponseError, %(#{response.code} '#{response.body}' returned when fetching #{remote_uri})
            end
          end
        end
      end
      local_uri
    end
  end
end
