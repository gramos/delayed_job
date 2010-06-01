$:.unshift(File.dirname(__FILE__) + '/../lib')
$: << File.dirname(__FILE__)

require 'rubygems'
require 'spec'
require 'logger'

gem 'activerecord', ENV['RAILS_VERSION'] if ENV['RAILS_VERSION']

#require 'active_support/dependencies'
#ActiveSupport::Dependencies.load_paths << File.dirname(__FILE__)

require 'delayed_job'
require 'sample_jobs'

Delayed::Worker.logger = Logger.new('/tmp/dj.log')
RAILS_ENV = 'test'


BACKENDS ||= []

def load_backend(backend, output = false)
  require 'backend/shared_backend_spec'

  begin
    require "setup/#{backend}"
    require "delayed/backend/#{backend}"
    Delayed::Worker.backend = backend
    BACKENDS << backend
  rescue => e
    puts "Unable to load #{backend} backend: #{e}"
    Delayed::Worker.logger.error "#{e} #{e.backtrace.join("\n")}"
  end

end



