# encoding: utf-8

module Tara
  # Jara compatible Archiver class that makes it easy to release artiftacts using
  # Tara and Jara.
  #
  # @example Release an artifact from a Rake task
  #   task :release do
  #     archiver = Tara::Archiver.new
  #     releaser = Jara::Releaser.new('production', 'artifact-bucket', archiver: archiver)
  #     releaser.release
  #   end
  #
  class Archiver
    # Create a new instance of `Archiver` with the specified configuration.
    #
    # The `Archiver` class supports the same configuration as {Archive#initialize}
    # does, with the addition of a `:metadata` option.
    #
    # @param [Hash] config
    # @option config [String] :app_dir (Dir.pwd) absolute path to the application
    #   directory.
    # @option config [String] :app_name (File.basename(@config[:app_dir])) name of
    #   the application.
    # @option config [String] :build_dir (File.join(@config[:app_dir], 'build'))
    #   the directory where the archive will be created.
    # @option config [String] :download_dir (File.join(@config[:build_dir], 'downloads'))
    #   the directory where Traveling Ruby artifacts will be downloaded.
    # @option config [String] :archive_name (@config[:app_name] + '.tgz') name of the archive
    # @option config [Array<String>] :files (%w[lib/**/*.rb]) list of globs that will be
    #   expanded when including source files in archive. Should be relative from `:app_dir`.
    # @option config [Array<String>] :executables (%w[bin/*]) list of globs that will be
    #   expanded when including executables in archive. Should be relative from `:app_dir`.
    # @option config [Array<String, String>] :gem_executables ([]) list of gem and exec name
    #   pairs which will be included as executables in archive.
    # @option config [String] :target (linux-x86_64) target platform that the archive will
    #   be created for. Should be one of "linux-x86", "linux-x86_64", or "osx".
    # @option config [String] :traveling_ruby_version (20150210) release of Traveling Ruby
    #   that should be used.
    # @option config [Array<String>] :without_groups (%w[development test]) list of gem
    #   groups to exclude from the archive.
    # @option config [Hash] :metadata ({}) addidtional metadata that the
    #   published artifact will be tagged with.
    #
    def initialize(config={})
      @config = config
      @config[:metadata] ||= {}
    end

    # Create a new archive
    #
    # @return [String] Path to the created archive
    #
    def create(options={})
      Archive.create(@config.merge(options))
    end

    # Extension used by this archiver
    #
    # @return [String] 'tgz'
    #
    def extension
      'tgz'
    end

    # Content type used by this archiver
    #
    # @return [String] 'application/x-gzip'
    #
    def content_type
      'application/x-gzip'
    end

    # Metadata that the published artifact will be tagged with.
    #
    # @return [Hash] Hash of key-value pairs that will be used as tags.
    #
    def metadata
      @config[:metadata]
    end
  end
end
