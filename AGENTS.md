# UltraSettings AI Coding Agent Instructions

## Project Overview
UltraSettings is a Ruby gem for managing application configuration from multiple sources (environment variables, runtime settings, YAML files) with built-in type safety, validation, and a web UI for documentation.

## Core Architecture

### Configuration Classes (Singleton Pattern)
- All configuration classes extend `UltraSettings::Configuration` and use Ruby's `Singleton` module
- Each configuration class has one instance accessible via `.instance`
- Register configurations globally: `UltraSettings.add(:test)` creates `UltraSettings.test` accessor
- Configuration classes support inheritance; subclasses maintain separate singleton instances

### Field Definition DSL
Fields are defined using the `field` class method with extensive options:
```ruby
field :timeout, type: :float, default: 1.0, 
      default_if: ->(val) { val <= 0 },
      description: "Network timeout in seconds",
      secret: false
```

### Multi-Source Value Resolution (Precedence Order)
1. **Environment Variables** - Highest priority (e.g., `MY_SERVICE_TIMEOUT`)
2. **Runtime Settings** - Dynamic configuration from external stores (e.g., Redis, `super_settings` gem)
3. **YAML Files** - File-based defaults with ERB support
4. **Default Values** - Fallback specified in field definition

### Type System
Supported types: `:string` (default), `:symbol`, `:integer`, `:float`, `:boolean`, `:datetime`, `:array`
- Boolean fields auto-generate `?` predicate methods (e.g., `enabled?`)
- Array type parses CSV strings from env vars, supports proper arrays from YAML
- Empty strings coerce to `nil` across all sources

## Key Conventions

### Naming Patterns
- **Configuration class names**: Must end in `Configuration` (e.g., `MyServiceConfiguration`)
- **Field names**: Match `/\A[a-z_][a-zA-Z0-9_]*\z/` pattern (snake_case)
- **Environment variable defaults**: `MY_SERVICE_FOO` for `MyServiceConfiguration#foo`
- **Runtime setting defaults**: `my_service.foo` (lowercase with dots)
- **YAML keys**: Match field name by default

### Customization Attributes
Set on configuration classes to override defaults:
- `env_var_prefix`, `env_var_delimiter`, `env_var_upcase` - Control environment variable naming
- `runtime_setting_prefix`, `runtime_setting_delimiter`, `runtime_setting_upcase` - Control runtime setting naming
- `configuration_file` - Specify explicit YAML file path
- `fields_secret_by_default` - Default secret status (true by default for security)
- Disable sources entirely: `environment_variables_disabled`, `runtime_settings_disabled`, `yaml_config_disabled`

### Thread Safety
- All memoized values protected by `Mutex`
- Override values are thread-local (keyed by `Thread.current.object_id`)
- Static fields are cached permanently after first access

## Testing Patterns

### Test Setup (spec/spec_helper.rb)
```ruby
# Configure YAML path and environment
UltraSettings.yaml_config_path = Pathname.new(__dir__) + "config"
UltraSettings.yaml_config_env = "test"

# Register configurations
UltraSettings.add(:test)
```

### Overriding Configuration Values
Use `override!` method for temporary value changes in tests:
```ruby
# Via UltraSettings module
UltraSettings.override!(test: {foo: "bar"}) { ... }

# Via configuration class
TestConfiguration.override!(foo: "bar") { ... }

# Via configuration instance
TestConfiguration.instance.override!(foo: "bar") { ... }
```

### RSpec Integration Example
```ruby
RSpec.configure do |config|
  config.around do |example|
    if example.metadata[:ultra_settings]
      UltraSettings.override!(example.metadata[:ultra_settings]) do
        example.run
      end
    end
  end
end
```

### Climate Control for Environment Variables
Uses `climate_control` gem to safely modify environment variables in tests:
```ruby
RSpec.describe "config", env: {TIMEOUT: "5"} do
  # Test with environment variable set
end
```

## Web UI Features

### Mounting the Rack App
```ruby
# config.ru or Rails routes
mount UltraSettings::RackApp.new(color_scheme: :system), at: "/settings"
```

### Key Capabilities
- Displays all registered configurations with descriptions
- Shows field metadata: type, description, sources, but **NOT actual values**
- Respects secret field marking (values hidden)
- Includes links to edit runtime settings via `UltraSettings.runtime_settings_url`
- Views in `lib/ultra_settings/*_view.rb` use ERB templates from `app/` directory

## Common Development Workflows

### Running Tests
```bash
bundle exec rake spec  # Default task runs all specs
bundle exec rspec spec/ultra_settings/configuration_spec.rb  # Specific file
```

### Checking Code Style
Uses Standard Ruby style guide (testdouble/standard):
```bash
bundle exec standardrb --fix
```

### Release Process
- Can only release from `main` branch (enforced in Rakefile)
- Version stored in `VERSION` file (no hardcoded version in gemspec)

## Special Features

### Static Fields
- Marked with `static: true`, values never change after first access
- Cannot be set from runtime settings (initialization-time only)
- Use for settings referenced during app boot

### Secret Fields
- All fields secret by default unless `fields_secret_by_default = false`
- Masked in `__to_hash__` output
- Runtime settings disabled on secret fields unless `UltraSettings.runtime_settings_secure = true`
- Secret status can be dynamic via Proc

### Conditional Defaults
Use `default_if` with Proc or method name to apply defaults based on loaded value:
```ruby
field :timeout, default: 1.0, default_if: ->(val) { val <= 0 }
```

### Introspection Methods
- `__source__(name)` - Returns which source provided the value (`:env`, `:runtime`, `:yaml`, `:default`)
- `__value_from_source__(name, source)` - Fetch value from specific source
- `__to_hash__` - Serialize current configuration as hash (secrets masked)

## Important Implementation Details

### Dynamic Method Generation
Fields create getter methods via `class_eval` for performance (avoids `method_missing`)

### YAML Configuration
- Supports environment-specific sections (e.g., `development`, `test`, `production`)
- Special `shared` section merged with environment-specific config
- ERB templates evaluated before YAML parsing
- Files searched in `UltraSettings.yaml_config_path`

### Runtime Settings Integration
- Must implement `[]` method accepting string argument
- Optional `array` method for native array support
- Use `UninitializedRuntimeSettings` during boot to catch premature access
- `super_settings` gem is recommended companion implementation

## File Organization

- `lib/ultra_settings/configuration.rb` - Core configuration class (630 lines)
- `lib/ultra_settings/field.rb` - Field metadata and resolution logic
- `lib/ultra_settings/coerce.rb` - Type coercion utilities
- `lib/ultra_settings/*.rb` - Supporting classes for web UI, YAML, helpers
- `spec/test_configs/` - Example configuration classes for testing
- `spec/config/` - YAML configuration files for tests
- `app/` - ERB templates and assets for web UI

## Key Dependencies
- Ruby >= 2.5
- Development: `rspec`, `climate_control`, `nokogiri`, `bundler`
- Optional: `super_settings` gem for runtime settings store
- Rails integration via `railtie.rb` when Rails is detected
