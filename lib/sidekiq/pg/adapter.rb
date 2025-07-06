require 'sidekiq/api'

module Sidekiq
  module Pg
    class Adapter
      def initialize(options = {})
        @pool = ConnectionPool.new(size: options[:pool_size] || Sidekiq::Pg.pool_size) do
          PG.connect(options[:database_url] || Sidekiq::Pg.database_url)
        end
        ensure_tables_exist
      end

      def push(queue, job_class, *args)
        job = {
          'class' => job_class.to_s,
          'args' => args,
          'queue' => queue.to_s,
          'jid' => SecureRandom.hex(12),
          'created_at' => Time.now.to_f,
          'enqueued_at' => Time.now.to_f
        }

        @pool.with do |conn|
          conn.exec_params(
            'INSERT INTO sidekiq_jobs (queue, job_data, created_at) VALUES ($1, $2, NOW())',
            [queue.to_s, JSON.generate(job)]
          )
        end

        job['jid']
      end

      def pop(queue, timeout = 1)
        @pool.with do |conn|
          result = conn.exec_params(
            'DELETE FROM sidekiq_jobs WHERE id = (
              SELECT id FROM sidekiq_jobs 
              WHERE queue = $1 
              ORDER BY created_at ASC 
              LIMIT 1
            ) RETURNING job_data',
            [queue.to_s]
          )

          return nil if result.ntuples == 0

          job_data = result[0]['job_data']
          JSON.parse(job_data)
        end
      end

      def size(queue)
        @pool.with do |conn|
          result = conn.exec_params('SELECT COUNT(*) FROM sidekiq_jobs WHERE queue = $1', [queue.to_s])
          result[0]['count'].to_i
        end
      end

      def clear(queue = nil)
        @pool.with do |conn|
          if queue
            conn.exec_params('DELETE FROM sidekiq_jobs WHERE queue = $1', [queue.to_s])
          else
            conn.exec('DELETE FROM sidekiq_jobs')
          end
        end
      end

      def queues
        @pool.with do |conn|
          result = conn.exec('SELECT DISTINCT queue FROM sidekiq_jobs ORDER BY queue')
          result.map { |row| row['queue'] }
        end
      end

      def stats
        @pool.with do |conn|
          result = conn.exec('SELECT queue, COUNT(*) as count FROM sidekiq_jobs GROUP BY queue')
          stats = {}
          result.each { |row| stats[row['queue']] = row['count'].to_i }
          stats
        end
      end

      private

      def ensure_tables_exist
        @pool.with do |conn|
          conn.exec(<<~SQL)
            CREATE UNLOGGED TABLE IF NOT EXISTS sidekiq_jobs (
              id SERIAL PRIMARY KEY,
              queue VARCHAR(255) NOT NULL,
              job_data JSONB NOT NULL,
              created_at TIMESTAMP DEFAULT NOW()
            )
          SQL

          conn.exec(<<~SQL)
            CREATE INDEX IF NOT EXISTS idx_sidekiq_jobs_queue_created 
            ON sidekiq_jobs (queue, created_at)
          SQL
        end
      end
    end
  end
end