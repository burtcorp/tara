# encoding: utf-8

require 'spec_helper'
require 'jara'


describe 'Jara compatibility' do
  def create_archive(dir, options={})
    original_app_dir = File.expand_path('../../resources/exapp', __FILE__)
    FileUtils.cp_r(original_app_dir, dir)
    app_dir = File.join(dir, 'exapp')
    setup_git(app_dir)
    Dir.chdir(app_dir) do
      archiver = Tara::Archiver.new(options)
      releaser = Jara::Releaser.new('production', nil, archiver: archiver, logger: Jara::NULL_LOGGER)
      releaser.build_artifact
    end
  end

  def archive_path
    @archive_path ||= Dir[File.join(tmpdir, 'exapp', 'build', 'production', 'exapp-production-*.tgz')].first
  end

  def setup_git(project_dir)
    Dir.chdir(project_dir) do
      [
        'git init --bare ../repo.git',
        'git init',
        'git add . && git commit -n -m "Initial commit"',
        'git remote add origin ../repo.git',
        'git push -u origin master'
      ].each do |command|
        Tara::Shell.exec(command + ' 2>&1')
      end
    end
  end

  def traveling_ruby_version
    ENV['TRAVELING_RUBY_VERSION']
  end

  before :all do
    create_archive(tmpdir, target: detect_target, download_dir: download_dir, traveling_ruby_version: traveling_ruby_version)
  end

  after :all do
    FileUtils.remove_entry_secure(tmpdir)
  end

  it 'creates an archive' do
    expect(File.exist?(archive_path)).to be true
  end

  it 'includes executables' do
    extract_archive
    output = %x(cd #{File.dirname(archive_path)} && ./exapp 2> /dev/null)
    expect(output).to match(/Running exapp/)
  end
end
