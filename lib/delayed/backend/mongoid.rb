require 'mongoid'

Mongoid::Document.class_eval do
  yaml_as "tag:ruby.yaml.org,2002:Mongoid"

  def self.yaml_new(klass, tag, val)
    klass.find(val['_id'])
  end

  def to_yaml_properties
    ['@_id']
  end
end

module Delayed
  module Backend
    module Mongoid
      class Job
        include ::Mongoid::Document
        include Delayed::Backend::Base
        include ::Mongoid::Timestamps

        self.collection_name = 'delayed_jobs'

        field :priority,    :type => Integer, :default => 0
        field :attempts,    :type => Integer, :default => 0
        field :handler,     :type => String
        field :run_at,      :type => Time
        field :locked_at,   :type => Time
        field :locked_by,   :type => String, :index => true
        field :failed_at,   :type => Time
        field :last_error,  :type => String

        before_save :set_default_run_at

        # ensure_index [[:priority, 1], [:run_at, 1]]

        def self.before_fork
          ::Mongoid.configure.master.connection.close
        end

        def self.after_fork
          ::Mongoid.configure.master.connection.connect_to_master
        end

        def self.db_time_now
          Time.now.utc
        end

        def self.ready_to_run(worker_name, max_run_time, limit = 5)
          r = criteria.where({ :run_at => { "$lte" => db_time_now }, :locked_at => nil,
                           :failed_at => nil}).limit(limit).all +

          criteria.where({ :run_at => { "$lte" => db_time_now },
                           :locked_at => { "$lte" => db_time_now - max_run_time },
                           :failed_at => nil} ).limit(limit).all +

          criteria.where({ :run_at => { "$lte" => db_time_now },
                           :locked_by => worker_name,  :failed_at => nil} ).limit(limit).all

          r[0..limit - 1]
        end

        def self.find_available(worker_name, limit = 5, max_run_time = Worker.max_run_time)
          ready_to_run(worker_name, max_run_time, limit)
        end

        # When a worker is exiting, make sure we don't have any locked jobs.
        def self.clear_locks!(worker_name)
          collection.update({:locked_by => worker_name},
                            {"$set" => {:locked_at => nil, :locked_by => nil}},
                            :multi => true)
        end

        # Lock this job for this worker.
        # Returns true if we have the lock, false otherwise.
        def lock_exclusively!(max_run_time, worker = worker_name)
          right_now = self.class.db_time_now
          overtime = right_now - max_run_time.to_i

          query = "this.locked_at == null || this.locked_at < #{make_date(overtime)} || this.locked_by == #{worker.to_json}"
          conditions = {:_id => id, :run_at => {"$lte" => right_now}, "$where" => query}

          collection.update(conditions, {"$set" => {:locked_at => right_now, :locked_by => worker}})
          affected_rows = collection.find({:_id => id, :locked_by => worker}).count
          if affected_rows == 1
            self.locked_at = right_now
            self.locked_by = worker
            return true
          else
            return false
          end
        end

      private

        def self.make_date(date_or_seconds)
          "new Date(#{date_or_seconds.to_f * 1000})"
        end

        def make_date(date)
          self.class.make_date(date)
        end
      end
    end
  end
end
