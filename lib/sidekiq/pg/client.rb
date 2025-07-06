module Sidekiq
  module Pg
    class Client
      def initialize(adapter = nil)
        @adapter = adapter || Adapter.new
      end

      def push(job)
        queue = job['queue'] || 'default'
        job_class = job['class']
        args = job['args'] || []

        @adapter.push(queue, job_class, *args)
      end

      def raw_push(jobs)
        jobs.each { |job| push(job) }
      end

      def size(queue = nil)
        if queue
          @adapter.size(queue)
        else
          @adapter.stats.values.sum
        end
      end

      def clear(queue = nil)
        @adapter.clear(queue)
      end

      def queues
        @adapter.queues
      end

      def stats
        @adapter.stats
      end
    end
  end
end