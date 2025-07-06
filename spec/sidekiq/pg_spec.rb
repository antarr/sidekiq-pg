require 'spec_helper'

RSpec.describe Sidekiq::Pg do
  it 'has a version number' do
    expect(Sidekiq::Pg::VERSION).not_to be nil
  end

  describe '.configure' do
    it 'allows configuration via block' do
      Sidekiq::Pg.configure do |config|
        config.database_url = 'postgres://test:test@localhost/test'
        config.pool_size = 10
      end

      expect(Sidekiq::Pg.database_url).to eq('postgres://test:test@localhost/test')
      expect(Sidekiq::Pg.pool_size).to eq(10)
    end
  end

  describe '.database_url' do
    it 'has a default value' do
      expect(Sidekiq::Pg.database_url).to eq('postgres://localhost/sidekiq_pg')
    end
  end

  describe '.pool_size' do
    it 'has a default value' do
      expect(Sidekiq::Pg.pool_size).to eq(5)
    end
  end
end