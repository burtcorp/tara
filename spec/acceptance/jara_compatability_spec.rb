# encoding: utf-8

require 'spec_helper'
require 'jara'


describe 'Jara compatability' do
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

  before :all do
    create_archive(tmpdir, target: detect_target, download_dir: download_dir)
  end

  after :all do
    FileUtils.remove_entry_secure(tmpdir)
  end

  it 'creates an archive' do
    expect(File.exist?(archive_path)).to be true
  end

  it 'includes executables' do
    extract_archive
    output = %x(cd #{File.dirname(archive_path)} && ./exapp)
    expect(output).to match(/Running/)
  end
end
