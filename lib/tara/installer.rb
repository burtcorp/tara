# encoding: utf-8

module Tara
  class Installer
    def initialize(package_dir, fetcher, options={})
      @package_dir = package_dir
      @fetcher = fetcher
      @without_groups = options[:without_groups]
      @app_dir = Pathname.new(options[:app_dir])
      @shell = options[:shell] || Shell
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
      create_bundler_config
    end

    private

    def bundler_command
      @bundler_command ||= begin
        command = 'BUNDLE_IGNORE_CONFIG=1 bundle install --jobs 4 --path vendor'
        command << %( --without #{@without_groups.join(' ')}) if @without_groups.any?
        command
      end
    end

    def bundle_gems
      FileUtils.mkdir_p(lib_path)
      Dir.mktmpdir do |tmpdir|
        copy_gem_files(Pathname.new(tmpdir))
        Dir.chdir(tmpdir) do
          Bundler.with_clean_env do
            @shell.exec(bundler_command)
          end
          Dir['vendor/*/*/cache/*'].each do |cached_file|
            FileUtils.rm_rf(cached_file)
          end
          Dir['vendor/ruby/*/extensions/*'].each do |ext_file|
            FileUtils.rm_rf(ext_file)
          end
          @shell.exec('find vendor/ruby/*/gems -name "*.o" -exec rm {} \; 2>&1 || true')
          @shell.exec('find vendor/ruby/*/gems -name "*.so" -exec rm {} \; 2>&1 || true')
          @shell.exec('find vendor/ruby/*/gems -name "*.bundle" -exec rm {} \; 2>&1 || true')
          FileUtils.cp_r('vendor', lib_path, preserve: true)
        end
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
        @shell.exec %(tar -xzf #{gem_archive_path} -C #{ruby_vendor_path})
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

    def create_bundler_config
      copy_gem_files(vendor_path)
      FileUtils.mkdir_p(bundle_path)
      File.open(bundle_path.join('config'), 'w+') do |f|
        f.puts(%(BUNDLE_PATH: .))
        f.puts(%(BUNDLE_WITHOUT: #{@without_groups.join(':')})) if @without_groups.any?
        f.puts(%(BUNDLE_DISABLE_SHARED_GEMS: '1'))
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
        @shell.exec(%(find #{ruby_vendor_path} -name "*.#{ext}" -exec rm {} \\; 2>&1))
      end
      @shell.exec(%(find #{ruby_vendor_path} -name "extconf.rb" -exec rm {} \\;))
      @shell.exec(%(find #{vendor_gems_glob.join('*', 'ext')} -name "Makefile" -exec rm {} \\; 2>&1))
      @shell.exec(%(find #{vendor_gems_glob.join('*', 'ext')} -name "tmp" -type d 2>&1 | xargs rm -rf))
    end

    def strip_java_files
      @shell.exec(%(find #{vendor_gems_glob} -name "*.java" -exec rm {} \\;))
    end

    def strip_git_files
      @shell.exec(%(find #{vendor_gems_glob} -name ".git" -type d | xargs rm -rf))
      @shell.exec(%(find #{bundler_gems_glob} -name ".git" -type d | xargs rm -rf))
    end

    def strip_from_gems(things)
      things.each do |thing|
        FileUtils.rm_r(Dir[vendor_gems_glob.join('*', thing)])
        FileUtils.rm_r(Dir[bundler_gems_glob.join('*', thing)])
      end
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

    def bundle_path
      @bundle_path ||= vendor_path.join('.bundle')
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
