require 'sidekiq'
require 'pg'
require 'connection_pool'
require 'json'

require_relative 'pg/version'
require_relative 'pg/adapter'
require_relative 'pg/client'
require_relative 'pg/worker'

module Sidekiq
  module Pg
    class << self
      def configure
        yield self if block_given?
      end

      def database_url
        @database_url ||= ENV['DATABASE_URL'] || 'postgres://localhost/sidekiq_pg'
      end

      def database_url=(url)
        @database_url = url
      end

      def pool_size
        @pool_size ||= 5
      end

      def pool_size=(size)
        @pool_size = size
      end
    end
  end
end