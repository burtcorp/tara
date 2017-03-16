# encoding: utf-8

require 'spec_helper'


describe 'bin/tara' do
  def app_name
    @app_name ||= 'exapp-test'
  end

  def app_dir
    @app_dir ||= File.expand_path('../../resources/exapp', __FILE__)
  end

  def build_dir
    @build_dir ||= File.expand_path('../../resources/exapp/build', __FILE__)
  end

  def download_dir
    @download_dir ||= ENV['TARA_DOWNLOAD_DIR'] || File.expand_path('../../../tmp/downloads', __FILE__)
  end

  def traveling_ruby_version
    ENV['TRAVELING_RUBY_VERSION']
  end

  def argv
    args = %W[--app-name #{app_name} --app-dir #{app_dir} --download-dir #{download_dir} --target #{detect_target}]
    if traveling_ruby_version
      args << '--traveling-ruby-version'
      args << traveling_ruby_version
    end
    args
  end

  def archive_path
    File.expand_path(%(../../resources/exapp/build/#{app_name}.tgz), __FILE__)
  end

  def create_archive
    @exit_code ||= Tara::Cli.new(argv).run
  end

  before :all do
    create_archive
  end

  after :all do
    FileUtils.remove_entry_secure(build_dir) if File.exists?(build_dir)
    FileUtils.remove_entry_secure(archive_path) if File.exists?(archive_path)
  end

  it 'creates a tar archive' do
    expect(File.exist?(archive_path)).to be true
  end

  it 'exits with code 0' do
    expect(create_archive).to be_zero
  end

  it 'includes executables' do
    extract_archive
    output = %x(cd #{File.dirname(archive_path)} && ./exapp 2> /dev/null)
    expect(output).to match(/Running exapp/)
  end

  context 'when an error occurs' do
    let :io do
      StringIO.new
    end

    before do
      allow(Tara::Shell).to receive(:exec).and_raise
    end

    it 'exits with status code 1 if an error occurs' do
      expect(Tara::Cli.new([], io).run).to eq(1)
    end

    it 'prints error message to given stream' do
      Tara::Cli.new(argv, io).run
      expect(io.string).to match(/Error during packaging: .+/)
    end
  end
end
