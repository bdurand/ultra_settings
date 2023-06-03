# Unified Rails Configuration :construction:

[![Continuous Integration](https://github.com/bdurand/ultra_settings/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/ultra_settings/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

This gem provides a method for managing settings in a Rails application. By using it you can write safer and cleaner code in your application and have a better method for documenting your various settings.

It allows you to define a hierarchy with three layers of settings:

1. Environment variables
2. Runtime settings (i.e. settings updatable from within the running application)
3. YAML configuration files

Settings at a higher level will override those set at a lower level. So, for instance, you can override values set in a YAML file with environment variables or runtime settings.

It also provides type casting for setting values so you can always be assured that values are returned as a predetermined class. The supported types are:

- String
- Integer
- Float
- Boolean
- Time
- Symbol
- Array<String>

You can also define default values to be returned in case the configured value is missing or it fails to match a constraint so you can rest assured that your app won't break if someone messes up the environment variables.

Settings are accessed through singleton classes that you define.

## Usage

### Acessing settings
```ruby
MyServiceConfiguration.instance.host

UltraSettings.add(:my_service)
UltraSettings.my_service.host

module MyApp
class Application < Rails::Application
  def settings
    UltraSettings
  end
end

Rails.application.settings.my_service.host
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

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
