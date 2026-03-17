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
        class_name = job['class']
        unless permitted_class?(class_name)
          raise SecurityError, "Unpermitted worker class: #{class_name}"
        end

        job_class = Object.const_get(class_name)
        worker = job_class.new
        worker.perform(*job['args'])
      rescue SecurityError => e
        puts "Security Error: #{e.message}"
      rescue => e
        Sidekiq.logger.error("Error processing job: #{e.message}")
        Sidekiq.logger.error(e.backtrace.join("\n"))
      end

      private

      def permitted_class?(class_name)
        return true if Sidekiq::Pg.permitted_classes.include?(class_name)

        # If no permitted classes are defined, we check if the class includes Sidekiq::Worker
        # this is a reasonable default but still more secure than arbitrary instantiation.
        if Sidekiq::Pg.permitted_classes.empty?
          begin
            klass = Object.const_get(class_name)
            return klass.is_a?(Class) && (klass.include?(Sidekiq::Worker) || (defined?(Sidekiq::Job) && klass.include?(Sidekiq::Job)))
          rescue NameError
            return false
          end
        end

        false
      end
    end
  end
end