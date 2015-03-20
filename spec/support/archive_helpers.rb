# encoding: utf-8

module ArchiveHelpers
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

  def tmpdir
    @tmpdir ||= Dir.mktmpdir
  end

  def download_dir
    @download_dir ||= ENV['TARA_DOWNLOAD_DIR'] || File.join(Dir.pwd, 'tmp', 'downloads')
  end
end

RSpec.configure do |config|
  config.include(ArchiveHelpers)
end
