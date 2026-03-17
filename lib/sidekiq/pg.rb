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
      attr_writer :database_url, :pool_size

      def configure
        yield self if block_given?
      end

      def permitted_classes
        @permitted_classes ||= []
      end

      def permitted_classes=(classes)
        @permitted_classes = classes
      end

      def database_url
        @database_url ||= ENV['DATABASE_URL'] || 'postgres://localhost/sidekiq_pg'
      end

      def pool_size
        @pool_size ||= 5
      end
    end
  end
end
