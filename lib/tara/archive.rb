# encoding: utf-8

module Tara
  class Archive
    def initialize(config={})
      @config = config
      @config[:app_dir] ||= Dir.pwd
      @config[:app_name] ||= File.basename(@config[:app_dir])
      @config[:build_dir] ||= File.join(@config[:app_dir], 'build')
      @config[:target_dir] ||= @config[:build_dir]
      @config[:download_dir] ||= File.join(@config[:build_dir], 'downloads')
      @config[:archive_name] ||= @config[:app_name] + '.tgz'
      @config[:files] ||= %w[lib/**/*.rb]
      @config[:executables] ||= %w[bin/*]
      @config[:target] ||= 'linux-x86_64'
      @config[:traveling_ruby_version] ||= '20150210'
      @config[:without_groups] ||= %w[development test]
    end

    def create
      Dir.mktmpdir do |tmp_dir|
        project_dir = Pathname.new(@config[:app_dir])
        package_dir = Pathname.new(tmp_dir)
        target_dir = Pathname.new(@config[:target_dir])
        install_dependencies(package_dir, fetcher)
        copy_source(project_dir, package_dir)
        copy_executables(project_dir, package_dir)
        Dir.chdir(tmp_dir) do
          create_archive(target_dir)
        end
        File.join(target_dir, @config[:archive_name])
      end
    end

    private

    DOT_PATH = Pathname.new('.')

    def copy_source(project_dir, package_dir)
      @config[:files].each do |glob_string|
        Pathname.glob(glob_string).each do |file|
          copy_file(project_dir, package_dir, file)
        end
      end
    end

    def copy_executables(project_dir, package_dir)
      Pathname.glob(*@config[:executables]).each do |executable|
        copy_file(project_dir, package_dir, executable)
        FileUtils.chmod(0755, package_dir.join(executable))
        create_exec_wrapper(package_dir, executable)
      end
    end

    def create_archive(target_dir)
      Shell.exec('tar -czf %s %s' % [@config[:archive_name], Dir['*'].join(' ')])
      FileUtils.mkdir_p(target_dir)
      FileUtils.cp(@config[:archive_name], target_dir)
    end

    def fetcher
      @fetcher ||= Fetcher.new(@config[:download_dir], @config[:target], @config[:traveling_ruby_version], @config).setup
    end

    def install_dependencies(package_dir, fetcher)
      Installer.new(package_dir, fetcher, @config).execute
    end

    def copy_file(project_dir, package_dir, file)
      unless file.dirname == DOT_PATH
        FileUtils.mkdir_p(package_dir.join(file.dirname))
      end
      FileUtils.cp(project_dir.join(file), package_dir.join(file))
    end

    def create_exec_wrapper(package_dir, executable)
      wrapper_path = package_dir.join(executable.basename)
      ex = Executable.new(executable.basename)
      File.open(wrapper_path, 'w') { |f| ex.write(f) }
      FileUtils.chmod(0755, wrapper_path)
    end
  end
end
