# encoding: utf-8

module AcceptanceHelpers
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

  def setup_git(project_dir)
    Dir.chdir(project_dir) do
      [
        'git init --bare ../repo.git',
        'git init',
        'git add . && git commit -m "Initial commit"',
        'git remote add origin ../repo.git',
        'git push -u origin master'
      ].each do |command|
        Tara::Shell.exec(command + ' 2>&1')
      end
    end
  end
end

RSpec.configure do |config|
  config.include(AcceptanceHelpers)
end
