require 'mongoid'

Mongoid.configure do |config|
  name = "delayed_job"
  host = "localhost"
  config.master = Mongo::Connection.new.db(name)
end

unless defined?(Story)
  class Story
    include ::Mongoid::Document

    def tell; text; end
    def whatever(n, _); tell*n; end
    def self.count; end

    handle_asynchronously :whatever
  end
end
