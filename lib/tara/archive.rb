# encoding: utf-8

module Tara
  # Packs an application along with a Ruby runtime and dependencies into a TAR archive.
  #
  # The archive will include the source code of your project (which is assumed to
  # be in the `lib` directory), wrapper scripts for each executable (assumed to be
  # in the `bin` directory), and all gems that aren't in the `test` or `development`
  # groups in your project's Gemfile.
  #
  # @example Creating an archive from a Rake task
  #   task :archive do
  #     Tara::Archive.new.create
  #   end
  #
  # @example Configuring the archive to be created
  #   task :archive do
  #     archive = Tara::Archive.new(
  #       target: 'osx',
  #       traveling_ruby_version: '20150204',
  #       without_groups: %w[test],
  #     )
  #     archive.create
  #   end
  #
  class Archive
    # Create a new instance of `Archive` with the specified configuration.
    #
    # Tara attempts to use sane defaults in most of all cases, for example like
    # assuming that the source code is in the `lib` directory of your project,
    # that the name of the application is the same as the project directory.
    #
    # @param [Hash] config
    # @option config [String] :app_dir (Dir.pwd) absolute path to the application
    #   directory.
    # @option config [String] :app_name (File.basename(@config[:app_dir])) name of
    #   the application.
    # @option config [String] :build_dir (File.join(@config[:app_dir], 'build'))
    #   the directory where the archive will be created.
    # @option config [Boolean] :bundle_ignore_config (false)
    #   if Bundler config should be ignored when installing dependencies
    # @option config [String] :download_dir (File.join(@config[:build_dir], 'downloads'))
    #   the directory where Traveling Ruby artifacts will be downloaded.
    # @option config [String] :archive_name (@config[:app_name] + '.tgz') name of the archive
    # @option config [Array<String>] :files (%w[lib/**/*.rb]) list of globs that will be
    #   expanded when including source files in archive. Should be relative from :app_dir.
    # @option config [Array<String>] :executables (%w[bin/*]) list of globs that will be
    #   expanded when including executables in archive. Should be relative from :app_dir.
    # @option config [Array<String, String>] :gem_executables ([]) list of gem and exec name
    #   pairs which will be included as executables in archive.
    # @option config [String] :target (linux-x86_64) target platform that the archive will
    #   be created for. Should be one of "linux-x86", "linux-x86_64", or "osx".
    # @option config [String] :traveling_ruby_version (20150210) release of Traveling Ruby
    #   that should be used.
    # @option config [Array<String>] :without_groups (%w[development test]) list of gem
    #   groups to exclude from the archive.
    #
    def initialize(config={})
      @config = config
      @config[:app_dir] ||= Dir.pwd
      @config[:app_name] ||= File.basename(@config[:app_dir])
      @config[:build_dir] ||= File.join(@config[:app_dir], 'build')
      @config[:download_dir] ||= File.join(@config[:build_dir], 'downloads')
      @config[:archive_name] ||= @config[:app_name] + '.tgz'
      @config[:files] ||= %w[lib/**/*.rb]
      @config[:executables] ||= %w[bin/*]
      @config[:gem_executables] ||= []
      @config[:target] ||= 'linux-x86_64'
      @config[:traveling_ruby_version] ||= '20150210'
      @config[:without_groups] ||= %w[development test]
    end

    # Short for `Archive.new(config).create`
    #
    # @return [String] Path to the archive
    #
    def self.create(config={})
      new(config).create
    end


    # Create an archive using the instance's configuration.
    #
    # @return [String] Path to the archive
    #
    def create
      Dir.mktmpdir do |tmp_dir|
        project_dir = Pathname.new(@config[:app_dir])
        package_dir = Pathname.new(tmp_dir)
        build_dir = Pathname.new(@config[:build_dir])
        copy_source(project_dir, package_dir)
        copy_executables(project_dir, package_dir)
        create_gem_shims(package_dir)
        install_dependencies(package_dir, fetcher)
        Dir.chdir(tmp_dir) do
          create_archive(build_dir)
        end
        File.join(build_dir, @config[:archive_name])
      end
    end

    private

    DOT_PATH = Pathname.new('.')

    def copy_source(project_dir, package_dir)
      @config[:files].each do |glob_string|
        Pathname.glob(project_dir.join(glob_string)).each do |file|
          copy_file(project_dir, package_dir, file)
        end
      end
    end

    def copy_executables(project_dir, package_dir)
      @config[:executables].each do |executable_glob|
        Pathname.glob(project_dir.join(executable_glob)).each do |executable|
          if executable.file?
            copy_file(project_dir, package_dir, executable)
            FileUtils.chmod(0755, package_dir.join(executable))
            relative_executable = executable.relative_path_from(project_dir)
            create_shim(package_dir, relative_executable)
          end
        end
      end
    end

    def create_gem_shims(package_dir)
      @config[:gem_executables].each do |gem_name, exec_name|
        create_gem_shim(package_dir, gem_name, exec_name)
      end
    end

    def create_archive(build_dir)
      Shell.exec('tar -czf %s %s' % [@config[:archive_name], Dir['*'].join(' ')])
      FileUtils.mkdir_p(build_dir)
      FileUtils.cp(@config[:archive_name], build_dir)
    end

    def fetcher
      @fetcher ||= Fetcher.new(@config[:download_dir], @config[:target], @config[:traveling_ruby_version], @config).setup
    end

    def install_dependencies(package_dir, fetcher)
      Installer.new(package_dir, fetcher, @config).execute
    end

    def copy_file(project_dir, package_dir, file)
      relative_file = file.relative_path_from(project_dir)
      if relative_file.directory?
        unless (dirname = relative_file.dirname) == DOT_PATH
          FileUtils.mkdir_p(package_dir.join(dirname))
        end
      else
        unless (dirname = relative_file.dirname) == DOT_PATH
          FileUtils.mkdir_p(package_dir.join(dirname))
        end
        FileUtils.cp(file, package_dir.join(relative_file))
      end
    end

    def create_shim(package_dir, executable)
      shim_path = package_dir.join(executable.basename)
      shim = ExecShim.new(*executable.split)
      File.open(shim_path, 'w') { |f| shim.write(f) }
      FileUtils.chmod(0755, shim_path)
    end

    def create_gem_shim(package_dir, gem_name, exec_name)
      shim_path = package_dir.join(exec_name)
      shim = GemShim.new(gem_name, exec_name)
      File.open(shim_path, 'w') { |f| shim.write(f) }
      FileUtils.chmod(0755, shim_path)
    end
  end
end
