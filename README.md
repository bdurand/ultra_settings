# UltraSettings

[![Continuous Integration](https://github.com/bdurand/ultra_settings/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/ultra_settings/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![Gem Version](https://badge.fury.io/rb/ultra_settings.svg)](https://badge.fury.io/rb/ultra_settings)

## Introduction

UltraSettings is a Ruby gem designed for managing application settings from various sources providing a consistent method for accessing configuration values. It simplifies your application's configuration management by allowing settings to be defined, documented, and accessed seamlessly.

UltraSettings emphasizes well-documented configuration. You can include documentation directly in the configuration code. The gem also includes a [web UI](#web-ui) that can be mounted as a Rack app or embedded in other views allowing admin users to easily view configuration settings and documentation.

## Table Of Contents

- [Key Features](#key-features)
- [Usage](#usage)
  - [Defining Configurations](#defining-configurations)
  - [Field Options](#field-options)
  - [Environment Variables](#environment-variables)
  - [Runtime Settings](#runtime-settings)
  - [YAML Files](#yaml-files)
  - [Removing The Hierarchy](#removing-the-hierarchy)
  - [Accessing Settings](#accessing-settings)
- [Web UI](#web-ui)
- [Testing With UltraSettings](#testing-with-ultrasettings)
- [Rollout Percentages](#rollout-percentages)
- [Installation](#installation)
- [Contributing](#contributing)
- [License](#license)

## Key Features

This gem supports a three-layer hierarchy for defining configuration sources:

1. Environment Variables
2. Runtime Settings (modifiable within the running application)
3. YAML Configuration Files

Settings from higher levels override those from lower ones. For example, values defined in environment variables or runtime settings will override those specified in YAML files. This hierarchy is optional — you can disable it and define specific data sources as needed for each configuration field.

### Simplified Access and Type Safety

With UltraSettings, your application code does not need to worry about how or from where a setting value is loaded from. Configuration settings can be accessed using plain Ruby objects and methods simplifying the development process.

The gem also ensures type safety by typecasting settings to specific data types, so you can rely on consistent data formats without manual type coercion. Supported types include:

- `String`
- `Integer`
- `Float`
- `Boolean`
- `Time`
- `Symbol`
- `Array<String>`

Additionally, you can define default values for settings, ensuring that a fallback value is available if a configuration is missing or does not meet constraints.

## Usage

### Defining Configurations

Configurations are defined as classes that extend from the `UltraSettings::Configuration` class. These configuration classes are [singleton classes](https://ruby-doc.org/3.2.2/stdlibs/singleton/Singleton.html).

You can define fields on your configuration classes with the `field` method. This will define a method on your configuration object with the given name.

```ruby
class MyServiceConfiguration < UltraSettings::Configuration
  self.fields_secret_by_default = false

  field :host, type: :string, description: "The hostname for the service"

  field :port, type: :integer, default: 80, description: "The port for the service"

  field :protocol, type: :string, default: "https", description: "The protocol for the service"

  field :timeout,
    type: :float,
    default: 1.0,
    default_if: ->(val) { val <= 0 },
    description: "Network timeout in seconds for requests to the service."

  field :auth_token,
    type: :string,
    env_var: "MY_SERVICE_TOKEN",
    runtime_setting: false,
    yaml_key: false,
    description: "Bearer token for accessing the service",
    secret: true

  # You aren't limited to just defining fields, you can define other
  # helper methods to make using the configuration easier.
  def uri
    URI("#{protocol}://#{host}:#{port}")
  end
end
```

#### Field Options

You can customize the behavior of each field using various options:

- `:type` -  Specifies the type of the field. The value of the setting will be cast to this type. If the value in the data source cannot be cast to the data type, then it will not be used. Supported types are:

  - `:string` (the default)
  - `:integer`
  - `:float`
  - `:boolean` (will accept case insensitive strings "true", "false", "1", "0", "t", "f", "yes", "no", "y", "n")
  - `:datetime`
  - `:symbol`
  - `:array` (of strings)

The array type will return an array of strings. If the raw value is a string (i.e. from an environment variable), it will be iterpreted as a comma separated list of values. You can use double quotes to group values that contain commas and backslashes to escape values. Leading and trailing whitespace will be stripped from each value.

- `:description` - Provides a description of the field. This is used for documentation purposes.

- `:default` - Sets a default value for the field. The value will be cast to the specified type.

- `:default_if` - Provides a condition for when the default should be used. This should be a Proc or the name of a method within the class. Useful for ensuring values meet specific constraints. This can provide protection from misconfiguration that can break the application. In the above example, the default value for `timeout` will be used if the value is less than or equal to 0.

- `:secret` - Marks the field as secret. Secret fields are not displayed in the web UI. By default, all fields are considered secret to avoid accidentally exposing sensitive values. You can change this default behavior by setting `fields_secret_by_default` to `false` either globally or per configuration.

- `:env_var` - Overrides the environment variable name used to populate the field. This is useful if the variable name does not follow the conventional pattern. Set this to `false` to disable loading the field from an environment variable.

- `:runtime_setting` - Overrides the runtime setting name for the field. Useful if the runtime setting name does not match the conventional pattern. Set this to `false` to disable loading the field from runtime settings.

- `:yaml_key` - Overrides the key in the YAML configuration file for this field. This is useful when the key does not match the field name. Set this to `false` to disable loading the field from a YAML file.

- `:static` - Marks the field as a static value. Static values cannot be changed once set and are not allowed to be set from runtime settings. Use this for settings that need to be referenced at the application is initializing.

### Environment Variables

Settings will first try to load values from environment variables. Environment variables are a good place to define environment specific values or sensitive values that you do not want to store in your codebase.

#### Default Behavior

By default, environment variables for settings are constructed using a prefix based on the configuration class name, with the field name appended. For example, a class named `Configs::MySettingsConfiguration` will use the prefix `CONFIGS_MY_SETTINGS_`, resulting in environment variables like `CONFIGS_MY_SETTINGS_HOST`.

#### Customizing Environment Variables

You can customize the behavior of environment variable naming in several ways:

- **Explicit Environment Variables:** You can specify the name of the environment variable to use for a field by setting the `env_var` option on the field. This allows you to use a different name than the default.

- **Lowercase Environment Variables:** Set `env_var_upcase` to false in your configuration class to use lowercase environment variable names.

- **Custom Delimiter:** The delimiter between module names and before the setting name can be customized by setting `env_var_delimiter` on your configuration class. For example, using a delimiter of "." in `Configs::MySettingsConfiguration` would produce environment variables like `CONFIGS.MY_SETTINGS.HOST`.

- **Custom Prefix:** Set `env_var_prefix` on your configuration class to specify an explicit prefix for environment variables. This allows for more flexibility in naming conventions.

- **Disabling Environment Variables:** You can disable environment variables as a default source for fields by setting `environment_variables_disabled` to `true` in your configuration class. You can disable environent variables on individual fields by setting `env_var` on the field to `false`.

If a setting value cannot be loaded from an environment variable, then it's value will attempt to be loaded from a runtime setting.

### Runtime Settings

Runtime settings are configurations loaded while your application is running, allowing for dynamic updates without needing to restart the application. This flexibility makes them ideal for settings that may change frequently or need quick adjustments.

#### Setting Up Runtime Settings

To enable runtime settings, set the `UltraSettings.runtime_settings` attribute to an object that implements a `[]` method and accepts a string argument. For example, to load runtime settings from a Redis database, you could use the following implementation:

```ruby
class RedisRuntimeSettings
  def initialize
    @redis = Redis.new
  end

  def [](name)
    @redis.get(name)
  end
end

UltraSettings.runtime_settings = RedisRuntimeSettings.new
```

#### Using the `super_settings` gem

There is a companion gem [super_settings](https://github.com/bdurand/super_settings) that can be used as a drop in implementation for the runtime settings. You just need to set the runtime settings to the `SuperSettings` object.

```ruby
UltraSettings.runtime_settings = SuperSettings
```

#### Customizing Runtime Settings

By default settings will be loaded from runtime settings by constructing a prefix from the configuration class name (i.e. `Configs::MySettingsConfiguration` uses the prefix `configs.my_settings.`) with the field name appended to it (e.g. `configs.my_settings.host`). By default runtime settings will be in all lowercase letters.

You can customize the behavior of runtime setting names with the following options:

- **Explicit Runtime Setting Names:** You can specify the name of the runtime setting to use for a field by setting the `runtime_setting` option on the field. This allows you to use a different name than the default.

- **Uppercase Runtime Setting Names:** Set `runtime_setting_upcase` to true in your configuration class to use uppercase runtime setting names.

- **Custom Delimiter:** Change the delimiter used between module names and before the setting name by setting `runtime_setting_delimiter` on your configuration class. For example, using a delimiter of "/" would produce runtime settings like `configs/my_settings/host`.

- **Custom Prefix:** Set `runtime_setting_prefix` on your configuration class to specify a custom prefix for runtime settings, giving you flexibility in naming conventions.

- **Disabling Runtime Settings:** You can disable runtime settings as a default source for fields by setting `runtime_settings_disabled` to `true` in your configuration class. You can disable runtime settings on individual fields by setting `runtime_setting` on the field to `false`.

- **Editing Links** You can specify a URL for editing runtime settings from the web UI by setting `UltraSettings.runtime_settings_url` to the desired URL. This will add links to the runtime settings in the web UI. You can use the placeholder `${name}` in the URL which will be replaced with the name of the runtime setting. If you are using the `super_settings` gem for runtime settings, then you can target a setting by adding `#edit=${name}` to the root URL where `super_settings` is mounted.

If a setting value cannot be loaded from the runtime settings, then it's value will attempt to be loaded from a YAML file.

### YAML Files

YAML files are the final source UltraSettings will check when loading configuration values. They provide a convenient way to store default values that can be distributed with your application code.

By default settings will be loaded from a YAML file determined by its class name (i.e. `Configs::MySettingsConfiguration` uses the file `configs/my_settings.yml`). The file is searched for in the path defined by `UltraSettings.yaml_config_path`. If the file does not exist, the YAML source strategy will not be used.

#### Customizing YAML Files

- **Explicit YAML Key:** You can specify the key in the YAML file to use for a field by setting the `yaml_key` option on the field. This allows you to use a different key than the default.

- **Custom YAML File Path:** You can specify an explicit YAML file by setting `configuration_file` on your configuration class to the desired file path.

- **Disable YAML Source:** To disable YAML files as a default source for your fields, set `yaml_config_disabled` to true on your configuration class. You can disable YAML files on individual fields by setting `yaml_key` on the field to `false`.

#### ERB Support

YAML files support ERB markup (i.e., <%= %>) that will be evaluated before the YAML is parsed. This feature allows for dynamically generated values within the YAML file.

#### Environment-Specific Configurations

YAML files can define environment-specific configurations. The file must contain a hash where the keys represent the names of your application environments (e.g., `development`, `test`, `production`). You can specify the environment to use by setting `UltraSettings.yaml_config_env` (default is "development").

A special key, `shared`, can be defined in the YAML file. The settings under this key will be merged with the environment-specific settings. Values from the specific environment will always overwrite those from `shared`.

#### Example YAML File

```yaml
shared:
  timeout: 5
  port: 8000

development:
  timeout: 10
  host: localhost

production:
  host: prod.example.com
```

The values for the development environment would be the combination of `development` and `shared`:

```ruby
{
  timeout: 10,
  port: 8000,
  host: "localhost"
}
```

While for production, the values would be the combination of `production` and `shared`:

```ruby
{
  timeout: 5,
  port: 8000,
  host: "prod.example.com"
}
```

#### Rails Integration

In a Rails application, the YAML environment will be set to the Rails environment and YAML files will be assumed to exist in the `config` directory.

### Removing The Hierarchy

If you prefer not to use the default hierarchy of environment variables, runtime settings, and YAML files, you can disable it. This allows you to explicitly define which data sources should be used for each field.

```ruby
class MyServiceConfiguration < UtraSettings::Configuration
  self.environment_variables_disabled = false
  self.runtime_settings_disabled = false
  self.yaml_config_disabled = false

field :host, yaml_key: "host"
  field :token, env_var: "MY_SERVICE_TOKEN"
  field :timeout, runtime_setting: "my_service.timeout", default: 5
end
```

If you don't want the hierarchy in any configuration, then you can disable it globally.

```ruby
UltraSettings.environment_variables_disabled = true
UltraSettings.runtime_settings_disabled = true
UltraSettings.yaml_config_disabled = true
```

### Accessing settings

Configurations in UltraSettings are singleton objects, and settings are accessed by calling methods directly on these objects.

```ruby
MyServiceConfiguration.instance.host
```

#### Adding Configurations to UltraSettings

To simplify access, you can add configurations to the `UltraSettings` object. UltraSettings will derive the configuration class name based on the name provided and define a method that returns the configuraiton object. For example:

```ruby
UltraSettings.add(:my_service)
UltraSettings.my_service # => MyServiceConfiguration.instance
UltraSettings.my_service.host
```

Alternatively, you can explicitly specify the class name to map to a method name:

```ruby
UltraSettings.add(:my, "MyServiceConfiguration")
UltraSettings.my.host
```

In a Rails application, you could add syntactic sugar by exposing the `UltraSettings` object as a helper method in application.rb.

```ruby
module MyApp
  class Application < Rails::Application
    def settings
      UltraSettings
    end
  end
end

Rails.application.settings.my_service.host
```

#### Using a Helper Method

To keep your codebase clean, especially if most configurations are accessed from within a specific class, you can encapsulate the configuration access in a helper method.


```ruby
class MyService

  # Reference the value as `settings.host`

  private

  def settings
    MyServiceConfiguration.instance
  end
end
```

### Web UI

UltraSettings provides a web UI via a mountable Rack application. You can use this to view the settings values and documentation. The UI will not display the value of any setting marked as secret.

![Web UI](assets/web_ui.png)

It is strongly recommended to secure the web UI with your application's authorization framework so that it is only visible to internal admin users.

#### Mounting the Web UI in a Rails Application

Below is an example of mounting the web UI in a Rails application using HTTP Basic authentication.


```ruby
# config/routes.rb

mount Rack::Builder.new do
  use Rack::Auth::Basic do |username, password|
    username == ENV.fetch("AUTH_USER") && password == ENV.fetch("AUTH_PASSWORD")
  end
  run UltraSettings::RackApp
end, at: "/ultra_settings"
```

You can specify the color scheme by setting by providing the `color_scheme` option to the `UltraSettings::RackApp` class. The default color scheme is `:light`. You can also set the scheme to `:dark` or `:system`.

```ruby
UltraSettings::RackApp.new(color_scheme: :dark)
```

#### Embedding the Settings View in Admin Tools

If you prefer to embed the settings view directly into your own admin tools or dashboard, you can use the `UltraSettings::ApplicationView` class to render the settings interface within your existing views:

```erb
<h1>Configuration</h1>

<%= UltraSettings::ApplicationView.new.render(select_class: "form-select", table_class: "table table-striped") %>
```

This approach allows for seamless integration of the settings UI into your application's admin interface, leveraging your existing authentication and authorization mechanisms. The settings are rendered in an HTML table with navigation handled by an HTML select element. You can specify the CSS classes for these elements and use your own stylesheets to customize the appearance.

You can also embed the view for individual configurations within your own views using the `UltraSettings::ConfigurationView` class if you want more customization:

```erb
<h1>My Service Settings</h1>

<%= UltraSettings::ConfigurationView.new(MyServiceConfiguration.instance).render(table_class: "table table-striped") %>
```

### Testing With UltraSettings

When writing automated tests, you may need to override configuration settings to test different scenarios. UltraSettings provides the `UltraSettings.override!` method to temporarily change settings within a test block. Below are examples of how to override the `TestConfiguration#foo` value in a test.

```ruby
# Override a configuration added on the global namespace.

# Note: you must have already added the configuration with UltraSettings.add(:test)
UltraSettings.override!(test: {foo: "bar"}) do
  expect(TestConfiguration.instance.foo).to eq "bar"
end

# or directly on the configuration class

TestConfiguration.override!(foo: "bar") do
  expect(TestConfiguration.instance.foo).to eq "bar"
end

# or on the instance itself

TestConfiguration.instance.override!(foo: "bar") do
  expect(TestConfiguration.instance.foo).to eq "bar"
end
```

#### RSpec Integration

If you are using RSpec, you can simplify overriding settings by setting up a global around hook. This hook will check for the presence of a :settings metadata key and apply the overrides automatically within the test block.


```ruby
# RSpec setup
RSpec.configure do |config|
  config.around(:each, :settings) do |example|
    if example.metadata[:settings].is_a?(Hash)
      UltraSettings.override!(example.metadata[:settings]) do
        example.run
      end
    else
      example.run
    end
  end
end
```

With this setup, you can easily specify settings overrides within individual test blocks using metadata:

```ruby
it 'has the settings I want', settings: {test: {foo: "bar"}} do
  expect(UltraSettings.test.foo).to eq("bar")
end
```

This approach keeps your tests clean and readable while allowing for flexible configuration management during testing.

### Rollout percentages

A common usage of configuration is to control rollout of new features by specifying a percentage value and then testing if a random number is less than it. If you implement this pattern in your configuration, then you should use something like the [consistent_random](https://github.com/bdurand/consistent_random) gem to ensure you are generating consistent values without your units of work.

```ruby
class MyServiceConfiguration < UltraSettings::Configuration
  field :use_http2_percentage,
    type: :float,
    default: 0.0,
    description: "Rollout percentage for using the new HTTP/2 driver"

  # Using ConsistentRandom#rand instead of Kernel#rand to ensure that we
  # get the same result within a request and don't oscillate back and forth
  # every time we check if this is enabled.
  def use_http2?
    ConsistentRandom.new("MyServiceConfiguration.use_http2").rand < use_http2_percentage
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "ultra_settings"
```

Then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install ultra_settings
```

## Contributing

Open a pull request on [GitHub](https://github.com/bdurand/ultra_settings).

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

You can start a local rack server to test the web UI by running

```bash
bundle exec rackup
```

You can test with some setting set by setting environment variable used in the test configuration.

```bash
MY_SERVICE_HOST=host.example.com MY_SERVICE_TOKEN=secret bundle exec rackup
```

You can test dark mode by setting the `COLOR_SCHEME` environment variable.

```bash
COLOR_SCHEME=dark bundle exec rackup
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
