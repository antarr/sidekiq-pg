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
  config.database_url = Rails.application.config.database_url || 
                       "postgres://localhost/#{Rails.application.class.module_parent_name.underscore}_#{Rails.env}"
  config.pool_size = ENV.fetch('SIDEKIQ_PG_POOL_SIZE', 5).to_i
end

# Replace Sidekiq's default Redis client with PostgreSQL adapter
Sidekiq.configure_server do |config|
  config.redis = { adapter: Sidekiq::Pg::Adapter.new }
end

Sidekiq.configure_client do |config|
  config.redis = { adapter: Sidekiq::Pg::Adapter.new }
end
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

- `DATABASE_URL`: PostgreSQL connection string
- `SIDEKIQ_PG_POOL_SIZE`: Connection pool size (default: 5)

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
