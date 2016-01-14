# encoding: utf-8

module Tara
  # @private
  class Installer
    def initialize(package_dir, fetcher, options={})
      @package_dir = package_dir
      @fetcher = fetcher
      @without_groups = options[:without_groups]
      @app_dir = Pathname.new(options[:app_dir])
      @bundle_env = bundle_env(options[:bundle_ignore_config])
      @shell = options[:shell] || Shell
      @build_command = options[:build_command]
    end

    def execute
      bundle_gems
      extract_ruby
      extract_native_gems
      strip_tests
      strip_docs
      strip_leftovers
      strip_java_files
      strip_git_files
      strip_empty_directories
    end

    private

    def bundle_env(ignore_config)
      env = {'BUNDLE_GEMFILE' => 'lib/vendor/Gemfile'}
      env['BUNDLE_IGNORE_CONFIG'] = '1' if ignore_config
      env
    end

    def bundler_command
      @bundler_command ||= begin
        command = 'bundle install --jobs 4 --path . --gemfile lib/vendor/Gemfile'
        command << %( --without #{@without_groups.join(' ')}) if @without_groups.any?
        command
      end
    end

    def bundle_gems
      FileUtils.mkdir_p(vendor_path)
      copy_gem_files(vendor_path)
      Dir.chdir(@package_dir) do
        Bundler.with_clean_env do
          copy_local_gems
          @shell.exec_with_env(bundler_command, @bundle_env)
          if @build_command
            @shell.exec_with_env(@build_command, @bundle_env)
          end
        end
        Dir['lib/vendor/*/*/cache/*'].each do |cache_file|
          FileUtils.rm_rf(cache_file)
        end
        Dir['lib/vendor/ruby/*/extensions/*'].each do |ext_file|
          FileUtils.rm_rf(ext_file)
        end
        %w[o so bundle].each do |ext|
          find_and_remove_files('lib/vendor/ruby/*/gems', %(*.#{ext}))
        end
      end
    end

    def find_installed_gems
      definition = Bundler::Definition.build('lib/vendor/Gemfile', 'lib/vendor/Gemfile.lock', false)
      @without_groups.each do |group|
        definition.add_optional_group(group)
      end
      definition.specs.each_with_object([]) do |gem_spec, specs|
        if gem_spec.full_gem_path.start_with?(Bundler.bundle_path.to_s) # Local gem
          specs << {
            :name => gem_spec.name,
            :full_name => gem_spec.full_name,
            :full_gem_path => gem_spec.full_gem_path,
            :spec_file => gem_spec.spec_file,
            :bin_dir => gem_spec.bin_dir,
            :relative_path => Pathname.new(gem_spec.full_gem_path).relative_path_from(Bundler.bundle_path).to_s,
          }
        end
      end
    rescue Bundler::GemNotFound => e
      []
    end

    def copy_local_gems
      local_gems = find_installed_gems
      target_directory = File.join(@package_dir, 'lib/vendor', Bundler.ruby_scope)

      spec_dir = File.join(target_directory, 'specifications')
      bin_dir = File.join(target_directory, 'bin')
      FileUtils.mkdir_p(spec_dir)
      FileUtils.mkdir_p(bin_dir)
      FileUtils.mkdir_p(File.join(target_directory, 'gems'))
      FileUtils.mkdir_p(File.join(target_directory, 'bundler', 'gems'))

      local_gems.each do |gemspec|
        FileUtils.cp_r(gemspec[:full_gem_path], File.join(target_directory, gemspec[:relative_path]))
        FileUtils.cp(gemspec[:spec_file], spec_dir) if File.exists?(gemspec[:spec_file])
      end
    end

    def extract_ruby
      FileUtils.mkdir_p(ruby_path)
      FileUtils.mkdir_p(ruby_vendor_path)
      ruby_archive_path = @fetcher.fetch_ruby
      @shell.exec(%(tar -xzf #{ruby_archive_path} -C #{ruby_path}))
    end

    def extract_native_gems
      native_gems = find_native_gems
      native_gems.each do |name, version|
        gem_archive_path = @fetcher.fetch_native_gem(name, version)
        @shell.exec(%(tar -xzf #{gem_archive_path} -C #{ruby_vendor_path}))
      end
    end

    def find_native_gems
      gemspecs = Dir[ruby_vendor_path.join('*/specifications/*.gemspec')]
      specs = gemspecs.map { |gemspec| Gem::Specification.load(gemspec) }
      with_ext = specs.select { |s| s.extensions.any? }
      with_ext.each_with_object({}) do |spec, hash|
        hash[spec.name] = spec.version.to_s
      end
    end

    def copy_gem_files(path)
      Dir['Gemfile', 'Gemfile.lock', '*.gemspec'].each do |file|
        if File.exist?(@app_dir.join(file))
          FileUtils.cp(@app_dir.join(file), path.join(File.basename(file)))
        end
      end
    end

    def strip_tests
      strip_from_gems(%w[tests test spec])
    end

    def strip_docs
      strip_from_gems(%w[doc* example* *.txt *.md *.rdoc])
    end

    def strip_leftovers
      %w[c cpp h rl].each do |ext|
        find_and_remove_files(ruby_vendor_path, %(*.#{ext}))
      end
      find_and_remove_files(ruby_vendor_path, 'extconf.rb')
      find_and_remove_files(vendor_gems_glob.join('*', 'ext'), 'Makefile')
      find_and_remove_directories(vendor_gems_glob.join('*', 'ext'), 'tmp')
    end

    def strip_java_files
      find_and_remove_files(vendor_gems_glob, '*.java')
    end

    def strip_git_files
      find_and_remove_directories(vendor_gems_glob, '.git')
      find_and_remove_directories(bundler_gems_glob, '.git')
    end

    def strip_from_gems(things)
      things.each do |thing|
        FileUtils.rm_r(Dir[vendor_gems_glob.join('*', thing)])
        FileUtils.rm_r(Dir[bundler_gems_glob.join('*', thing)])
      end
    end

    def strip_empty_directories
      @shell.exec(%(find #{@package_dir} -type d -empty -delete 2> /dev/null || true))
    end

    def find_and_remove_files(dir, glob)
      @shell.exec(%(find #{dir} -name "#{glob}" -type f -exec rm -f "{}" \\; 2> /dev/null || true))
    end

    def find_and_remove_directories(dir, glob)
      @shell.exec(%(find #{dir} -name "#{glob}" -type d -exec rm -rf "{}" \\; 2> /dev/null || true))
    end

    def lib_path
      @lib_path ||= Pathname.new(@package_dir).join('lib')
    end

    def vendor_path
      @vendor_path ||= lib_path.join('vendor')
    end

    def ruby_vendor_path
      @ruby_vendor_path ||= vendor_path.join('ruby')
    end

    def ruby_path
      @ruby_path ||= lib_path.join('ruby')
    end

    def bundler_gems_glob
      @bundler_gems_glob ||= ruby_vendor_path.join('*', 'bundler', 'gems')
    end

    def vendor_gems_glob
      @vendor_gems_glob ||= ruby_vendor_path.join('*', 'gems')
    end
  end
end
