# encoding: utf-8

require 'spec_helper'


module Tara
  describe Archiver do
    let :archiver do
      described_class.new(options)
    end

    let :options do
      {}
    end

    describe '#extension' do
      it 'returns `tgz`' do
        expect(archiver.extension).to eq('tgz')
      end
    end

    describe '#content_type' do
      it 'returns a gzip content type' do
        expect(archiver.content_type).to eq('application/x-gzip')
      end
    end

    describe '#metadata' do
      context 'by default' do
        it 'returns an empty Hash' do
          expect(archiver.metadata).to eq({})
        end
      end

      context 'when overridden' do
        let :options do
          {metadata: {meta: 'data'}}
        end

        it 'returns the overridden value' do
          expect(archiver.metadata).to eq({meta: 'data'})
        end
      end
    end
  end
end
