$:.unshift(File.dirname(__FILE__) + '/../lib')
$: << File.dirname(__FILE__)

require 'rubygems'
require 'spec'
require 'logger'

gem 'activerecord', ENV['RAILS_VERSION'] if ENV['RAILS_VERSION']

require 'active_support/dependencies'
ActiveSupport::Dependencies.load_paths << File.dirname(__FILE__)

require 'delayed_job'
require 'sample_jobs'

Delayed::Worker.logger = Logger.new('/tmp/dj.log')
RAILS_ENV = 'test'

BACKENDS ||= []

def load_backend(backend)
  require 'backend/shared_backend_spec'
  puts "--> Loading #{backend} backend..."
  begin
    require "setup/#{backend}"
    require "delayed/backend/#{backend}"
    Delayed::Worker.backend = backend
    BACKENDS << backend
  rescue => e
    puts "Unable to load #{backend} backend: #{e}"
    puts "#{e} #{e.backtrace.join("\n")}"
  end

end



