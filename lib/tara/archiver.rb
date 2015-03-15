# encoding: utf-8

module Tara
  class Archiver
    def initialize(options={})
      @options = options
    end

    def create(options={})
      Archive.new(@options.merge(options)).create
    end

    def extension
      @options[:extension] || 'tgz'
    end

    def content_type
      'application/x-gzip'
    end

    def metadata
      @options[:metadata] || {}
    end
  end
end
