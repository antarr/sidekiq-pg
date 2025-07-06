module Sidekiq
  module Pg
    class Worker
      def initialize(adapter = nil, queues = ['default'])
        @adapter = adapter || Adapter.new
        @queues = queues
        @running = false
      end

      def start
        @running = true
        @thread = Thread.new { work_loop }
      end

      def stop
        @running = false
        @thread&.join
      end

      private

      def work_loop
        while @running
          job = fetch_job
          if job
            process_job(job)
          else
            sleep(1)
          end
        end
      end

      def fetch_job
        @queues.each do |queue|
          job = @adapter.pop(queue)
          return job if job
        end
        nil
      end

      def process_job(job)
        job_class = Object.const_get(job['class'])
        worker = job_class.new
        worker.perform(*job['args'])
      rescue => e
        puts "Error processing job: #{e.message}"
        puts e.backtrace
      end
    end
  end
end