# YARD UltraSettings Plugin

[![Continuous Integration](https://github.com/bdurand/ultra_settings/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/ultra_settings/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![Gem Version](https://badge.fury.io/rb/yard-ultra_settings.svg)](https://badge.fury.io/rb/yard-ultra_settings)

A YARD plugin that automatically generates documentation for UltraSettings configuration field definitions.

## Usage

After installing the gem, add the following to your project's `.yardopts` file:

```
--plugin ultra_settings
```

This tells YARD to load the plugin when generating documentation. Once configured, the plugin automatically enhances YARD documentation for any classes that inherit from `UltraSettings::Configuration`. When you define fields using the `field` method, YARD will automatically generate method documentation with proper types and return values.

### Example

```ruby
class MyServiceConfiguration < UltraSettings::Configuration
  # Maximum number of concurrent connections
  field :max_connections, type: :integer, default: 5

  # Timeout for service requests in seconds
  field :timeout, type: :float, default: 2.0

  # Enable debug mode
  field :debug_mode, type: :boolean, default: false
end
```

When you run `yard doc`, the plugin will automatically generate documentation for:
- `#max_connections` → Returns `Integer`
- `#timeout` → Returns `Float`
- `#debug_mode` → Returns `Boolean`
- `#debug_mode?` → Returns `Boolean` (predicate method for boolean fields)

### Type Mappings

The plugin automatically maps UltraSettings field types to YARD types:

- `:string` → `String, nil`
- `:symbol` → `Symbol, nil`
- `:integer` → `Integer, nil`
- `:float` → `Float, nil`
- `:boolean` → `Boolean` (never nil)
- `:datetime` → `Time, nil`
- `:array` → `Array<String>, nil`

Fields with default values (and no `default_if` option) are documented as non-nullable.

### Documenting Fields

Add comments directly before field definitions to provide descriptions:

```ruby
# The API key for external service integration.
# This value is loaded from the API_KEY environment variable.
field :api_key, type: :string, secret: true
```

## Installation

Add this line to your application's Gemfile:

```ruby
group :development, :test do
  gem 'yard-ultra_settings'
end
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install yard-ultra_settings

## Contributing

Open a pull request on [GitHub](https://github.com/bdurand/ultra_settings).

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
