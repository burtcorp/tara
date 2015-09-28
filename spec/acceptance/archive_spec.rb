# encoding: utf-8

require 'spec_helper'


module Tara
  describe Archive do
    describe '#create' do
      def create_archive(dir, options={})
        original_app_dir = File.expand_path('../../resources/exapp', __FILE__)
        FileUtils.cp_r(original_app_dir, dir)
        app_dir = File.join(dir, 'exapp')
        Dir.chdir(app_dir) do
          output_path = described_class.create(options)
          FileUtils.cp(output_path, dir)
        end
      end

      def archive_path
        @archive_path ||= File.join(tmpdir, 'exapp', 'build', 'exapp.tgz')
      end

      def entries
        @entries ||= archive.map { |entry| entry }
      end

      def listing
        @listing ||= entries.map(&:full_name)
      end

      def tar_entry_contents(name)
        archive.rewind
        e = archive.find { |e| e.full_name == name }
        e.read
      end

      def traveling_ruby_version
        ENV['TRAVELING_RUBY_VERSION']
      end

      before :all do
        WebMock.disable!
      end

      after :all do
        FileUtils.remove_entry_secure(tmpdir)
        WebMock.enable!
      end

      context 'with standard options' do
        before :all do
          create_archive(tmpdir, target: detect_target, download_dir: download_dir, traveling_ruby_version: traveling_ruby_version)
          extract_archive
        end

        it 'includes the project\'s source files' do
          expect(listing).to include('lib/exapp/cli.rb')
        end

        it 'includes the project\'s executables' do
          expect(listing).to include('bin/exapp')
        end

        it 'creates a wrapper for each executable and places it at the top level' do
          expect(listing).to include('exapp')
          output = %x(cd #{File.dirname(archive_path)} && ./exapp 2> /dev/null)
          expect(output).to match(/Running exapp/)
        end

        it 'ignores directories in `executables` glob' do
          expect(listing).to_not include('bin/bindir')
        end

        it 'bundles gems into `lib/vendor/ruby/<VERSION>/gems`' do
          gems = listing.select { |e| e =~ /lib\/vendor\/ruby\/.*\/gems\/.*/ }
          expect(gems).to_not be_empty
        end

        it 'includes gems that are defined in gem groups' do
          gems = listing.select { |e| e =~ /lib\/vendor\/ruby\/.*\/gems\/rack-test.*/ }
          expect(gems).to_not be_empty
        end

        it 'includes git gems' do
          gems = listing.select { |e| e =~ /lib\/vendor\/ruby\/.*\/gems\/thor.*/ }
          expect(gems).to_not be_empty
        end

        it 'puts Ruby stdlib into lib/ruby/lib/ruby/<VERSION>' do
          entry = listing.find { |e| e =~ /lib\/ruby\/lib\/ruby\/.*\/pp\.rb/ }
          expect(entry).to_not be_nil
        end

        it 'removes cached files' do
          cached = listing.select { |e| e =~ /vendor\/.*\/.*\/cache\/.+/ }
          expect(cached).to be_empty
        end

        it 'strips tests from bundled gems' do
          tests = listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/[^\/]+\/tests/ }
          tests += listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/[^\/]+\/test/ }
          tests += listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/[^\/]+\/spec/ }
          expect(tests).to be_empty
        end

        it 'strips documentation from bundled gems' do
          doc = listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/[^\/]+\/doc/ }
          doc += listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/[^\/]+\/example/ }
          doc += listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/.+\/*.txt$/ }
          doc += listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/.+\/*.rdoc$/ }
          doc += listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/.+\/*.md$/ }
          expect(doc).to be_empty
        end

        it 'removes leftover native ext. sources and compilation objects' do
          leftovers = listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/.+\/ext\/Makefile/ }
          leftovers += listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/.+\/ext\/.*\/tmp/ }
          leftovers += listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/.+\/ext\/.*\/Makefile/ }
          leftovers += listing.select { |e| e =~ /lib\/vendor\/ruby\/.*\.c$/ }
          leftovers += listing.select { |e| e =~ /lib\/vendor\/ruby\/.*\.cpp$/ }
          leftovers += listing.select { |e| e =~ /lib\/vendor\/ruby\/.*\.h$/ }
          leftovers += listing.select { |e| e =~ /lib\/vendor\/ruby\/.*\.rl$/ }
          leftovers += listing.select { |e| e =~ /lib\/vendor\/ruby\/.*\/extconf\.rb$/ }
          leftovers += listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/.*\.o$/ }
          leftovers += listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/.*\.so$/ }
          leftovers += listing.select { |e| e =~ /lib\/vendor\/ruby\/.+\/gems\/.*\.bundle$/ }
          expect(leftovers).to be_empty
        end

        it 'strips Java source files' do
          java_files = listing.select { |e| e =~ /\.java$/ }
          expect(java_files).to be_empty
        end

        it 'strips files related to Git' do
          git_files = listing.select { |e| e =~ /\.git\/.*/ }
          expect(git_files).to be_empty
        end
      end

      context 'with custom options' do
        before :all do
          create_archive(tmpdir, {
            files: %w[lib/*],
            executables: %w[bin/* ext/*],
            target: detect_target,
            download_dir: download_dir,
            without_groups: %w[ignore],
            traveling_ruby_version: traveling_ruby_version,
          })
          extract_archive
        end

        it 'recursively includes source files' do
          expect(listing).to include('lib/exapp/cli.rb')
        end

        it 'excludes gems in given `without_groups` option' do
          gems = listing.select { |e| e =~ /lib\/vendor\/ruby\/.*\/gems\/rack-test.*/ }
          expect(gems).to be_empty
        end

        it 'correctly creates wrapper scripts for executables that aren\'t in the `bin` directory' do
          expect(listing).to include('nonbin')
          output = %x(cd #{File.dirname(archive_path)} && ./nonbin)
          expect(output.strip).to eq('Hello world')
        end
      end
    end
  end
end
