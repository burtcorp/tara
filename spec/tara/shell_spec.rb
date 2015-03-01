# encoding: utf-8

require 'spec_helper'


module Tara
  describe Shell do
    let :shell do
      described_class
    end

    let :tmpdir do
      Dir.mktmpdir
    end

    after do
      FileUtils.remove_entry_secure(tmpdir)
    end

    describe '.exec' do
      context 'with a successful command' do
        it 'returns the output of the command' do
          expect(shell.exec(%(ls -l #{tmpdir}))).to be_empty
        end
      end

      context 'with an unsuccessful command' do
        it 'raises an ExecError' do
          expect { shell.exec(%(ls -l #{tmpdir}/hello/world 2> /dev/null)) }.to raise_error(ExecError, /Command `ls -l .+` failed with output/)
        end
      end
    end
  end
end
