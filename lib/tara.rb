# encoding: utf-8

require 'pathname'
require 'tmpdir'


module Tara
  TaraError = Class.new(StandardError)
  ExecError = Class.new(TaraError)
  NotFoundError = Class.new(TaraError)
  TooManyRedirectsError = Class.new(TaraError)
end

require 'tara/archive'
require 'tara/cli'
require 'tara/executable'
require 'tara/fetcher'
require 'tara/installer'
require 'tara/shell'
