# encoding: utf-8

module Tara
  class Archiver
    def initialize(config={})
      @config = config
      @config[:metadata] ||= {}
    end

    def create(options={})
      Archive.create(@config.merge(options))
    end

    def extension
      'tgz'
    end

    def content_type
      'application/x-gzip'
    end

    def metadata
      @config[:metadata]
    end
  end
end
