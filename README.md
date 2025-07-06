# sidekiq-pg

A PostgreSQL adapter for Sidekiq that uses unlogged tables for high-performance job storage.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-pg'
```

And then execute:

    $ bundle install

## Usage

### Basic Usage

Configure the PostgreSQL connection:

```ruby
require 'sidekiq/pg'

Sidekiq::Pg.configure do |config|
  config.database_url = 'postgres://user:pass@localhost/sidekiq_db'
  config.pool_size = 5
end
```

Use the adapter:

```ruby
# Create adapter
adapter = Sidekiq::Pg::Adapter.new

# Push jobs
adapter.push('default', 'MyWorker', 'arg1', 'arg2')

# Pop jobs
job = adapter.pop('default')

# Get queue size
size = adapter.size('default')

# Clear queue
adapter.clear('default')
```

### Rails Integration

Add to your Gemfile:

```ruby
gem 'sidekiq-pg'
```

Create an initializer `config/initializers/sidekiq_pg.rb`:

```ruby
require 'sidekiq/pg'

Sidekiq::Pg.configure do |config|
  config.database_url = ENV.fetch('DATABASE_URL', 'postgres://postgres:postgres@postgres:5432/sidekiq_db')
  config.pool_size = ENV.fetch('SIDEKIQ_PG_POOL_SIZE', 5).to_i
end
```

Create/update your main Sidekiq initializer `config/initializers/sidekiq.rb`:

```ruby
require 'sidekiq/web'
require 'sidekiq-unique-jobs'
require 'sidekiq/worker_killer'

Sidekiq.configure_server do |config|
  config.redis = { adapter: Sidekiq::Pg::Adapter.new(database_url: ENV.fetch('DATABASE_URL', 'postgres://postgres:postgres@postgres:5432/sidekiq_db')) }
  config[:dead_max_jobs] = 100_000

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
    chain.add Sidekiq::WorkerKiller, max_rss: 2048
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = { adapter: Sidekiq::Pg::Adapter.new(database_url: ENV.fetch('DATABASE_URL', 'postgres://postgres:postgres@postgres:5432/sidekiq_db')) }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

Sidekiq.strict_args!(false)
```

Create your workers as usual:

```ruby
class MyWorker
  include Sidekiq::Worker

  def perform(arg1, arg2)
    # Your job logic here
  end
end
```

Enqueue jobs:

```ruby
MyWorker.perform_async('arg1', 'arg2')
```

### Environment Variables

You can configure the gem using environment variables:

- `DATABASE_URL`: PostgreSQL connection string (e.g., `postgres://postgres:postgres@postgres:5432/sidekiq_db`)
- `SIDEKIQ_PG_POOL_SIZE`: Connection pool size (default: 5)

### Docker/Container Setup

For containerized environments, ensure your PostgreSQL container is accessible:

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    environment:
      DATABASE_URL: postgres://postgres:postgres@postgres:5432/sidekiq_db
    depends_on:
      - postgres
  
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: wevote_development
```

Create the sidekiq database:

```bash
PGPASSWORD=postgres psql -h postgres -U postgres -c "CREATE DATABASE sidekiq_db;"
```

### Important Configuration Notes

1. **Database URL Parameter**: Pass the `database_url` parameter directly to the adapter constructor to ensure proper connection routing in containerized environments.

2. **Separate Database**: It's recommended to use a separate database for Sidekiq jobs to avoid conflicts with your main application database.

3. **Connection Configuration**: The adapter uses the configuration from `Sidekiq::Pg.configure` by default, but you can override it by passing parameters directly to the constructor.

## Features

- Uses PostgreSQL unlogged tables for better performance
- Connection pooling support
- Compatible with Sidekiq's job format
- Thread-safe operations
- Atomic job processing

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
