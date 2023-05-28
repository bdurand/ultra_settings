# Unified Rails Configuration :construction:

[![Continuous Integration](https://github.com/bdurand/consolidated_settings/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/consolidated_settings/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

TODO

## Usage

```ruby
UnifiedSettings

CombinedSettings

CompositeConfig

CompositeSettings

ConsolidatedSettings.my_service.host

UnifiedRailsConfig.my_service.host

Config.my_service.host

$config.my_service.host

Rails.consolidated_settings.my_service.host

Rails.app_config.my_service.host
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "consolidated_settings"
```

Then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install consolidated_settings
```

## Contributing

Open a pull request on [GitHub](https://github.com/bdurand/consolidated_settings).

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
