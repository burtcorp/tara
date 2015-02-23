# encoding: utf-8

require 'spec_helper'
require 'rubygems/package'
require 'zlib'


module Tara
  describe Archive do
    describe '#create' do
      def create_archive(dir, options={})
        original_app_dir = File.expand_path('../../resources/exapp', __FILE__)
        FileUtils.cp_r(original_app_dir, dir)
        app_dir = File.join(dir, 'exapp')
        Dir.chdir(app_dir) do
          archive = described_class.new(options)
          output_path = archive.create
          FileUtils.cp(output_path, dir)
        end
      end

      def archive_path
        @archive_path ||= File.join(tmpdir, 'exapp', 'build', detect_target, 'exapp.tgz')
      end

      def extract_archive
        %x(tar -xzf #{archive_path} -C #{File.dirname(archive_path)})
      end

      def archive
        @archive ||= begin
          r = Gem::Package::TarReader.new(Zlib::GzipReader.open(archive_path))
          r.rewind
          r
        end
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

      def tmpdir
        @tmpdir ||= Dir.mktmpdir
      end

      def download_dir
        @download_dir ||= ENV['TARA_DOWNLOAD_DIR'] || File.join(Dir.pwd, 'tmp', 'downloads')
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
          create_archive(tmpdir, target: detect_target, download_dir: download_dir)
          extract_archive
        end

        it 'includes the project\'s source files' do
          expect(listing).to include('exapp/lib/exapp/cli.rb')
        end

        it 'includes the project\'s executables' do
          expect(listing).to include('exapp/bin/exapp')
        end

        it 'creates a wrapper for each executable and places it at the top level' do
          expect(listing).to include('exapp/exapp')
          output = %x(cd #{File.dirname(archive_path)} && ./exapp/exapp)
          expect(output).to match(/Running/)
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
      end

      context 'with custom options' do
        before :all do
          create_archive(tmpdir, target: detect_target, download_dir: download_dir, without_groups: %w[ignore])
          extract_archive
        end

        it 'excludes gems in given `without_groups` option' do
          gems = listing.select { |e| e =~ /lib\/vendor\/ruby\/.*\/gems\/rack-test.*/ }
          expect(gems).to be_empty
        end
      end
    end
  end
end
