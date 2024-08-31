# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.1.0

### Added

- Revamped web UI that can now display setting values.
- Added option to specify fields as a secret in the configuration to prevent exposing sensitive information in the web interface. By default all fields are considered secrets. This can be changed per configuration by setting the `fields_secret_by_default` property to `false`.
- Added `UltraSettings::ConfigurationView` which can be used to embed the HTML table showing the configuration options and values other admin views. So now you can integrate the settings view into your own admin tools.
- Add `__to_hash__` method to `UltraSettings::Configuration` which can to serialize the current configuration values as a hash. This value can be used for comparing configuration between environments.

## 1.0.1

### Added
- Optimize object shapes for the Ruby interpreter by declaring instance variables in constructors.

## 1.0.0

### Added
- Initial release.
