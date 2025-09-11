# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.7.0

### Added

- Added new setting to indicate if the runtime settings engine is secure. If the engine is marked as not secure, then runtime settings will be disabled for all fields marked as secret. This protects sensitive information from being exposed in the web UI or through the API. The default value is `true` to maintain backwards compatibility.

## 2.6.1

### Added

- Show icons on the web UI that open a dialog with the current value for each data source.

## 2.6.0

### Added

- Added support for passing the type in `UltraSettings.runtime_settings_url` as `${type}` in the URL.

### Changed

- Significantly updated the web UI to improve the layout and usability. The UI is no longer an HTML table and has a cleaner, more modern design.

## 2.5.0

### Added

- Added mechanism for guarding against using runtime settings during initialization with the `UltraSettings::UninitializedRuntimeSettings` class.

### Changed

- Runtime settings will now try to load arrays from runtime settings using the `array` method if it is defined. This provides for better integration with the `super_settings` gem to avoid coercing values to and from strings.

## 2.4.5

### Fixed

- Add check for nil YAML config path to avoid error loading YAML file if the path is not set.

## 2.4.4

### Changed

- Return true for `yaml_config_disabled?` if the configuration file has been set to nil.

## 2.4.3

### Fixed

- Fixed error raised when showing web UI if a configuration has set the YAML file to `false`.

## 2.4.2

### Changed

- Configuration setup set prior to loading the railtie will no longer be overridden by the railtie default setup.

## 2.4.1

### Changed

- Ignore base configuration classes that don't have any fields defined in the web UI.
- Allow overriding values on static fields in tests.
- Changed Web UI CSS variable scope to apply to all application elements.

## 2.4.0

### Added

- Added the `UltraSettings::ConfigHelper` module to add convenience methods `config` on the class and instance.

## 2.3.0

### Added

- Added logic for parsing arrays from environment variables. Array fields can now be set as comma delimited strings in an environment variable.

### Fixed

- Mixed case boolean values are now handled properly so that "False" is interpreted as `false` and "True" is interpreted as `true`.

## 2.2.0

### Added

- Added option for `UltraSettings.runtime_settings_url` to allow configuring a link for editing runtime settings from the web UI.

## 2.1.0

### Added

- Added option to specify the color scheme for the web UI when mounting the rack app to support dark mode.

### Fixed

- Times stored as strings representing the seconds since the epoch are now correctly parsed as Time objects.

## 2.0.0

### Fixed

- **Breaking Change:** Fix conflict with overridding the standard `include?` method on configuration classes. These methods are now defined as `UltraSettings.added?` and `UltraSettings::Configuration.include_field?`.
- **Breaking Change:** Include namespace in autoloaded configuration names for Rails applications to avoid conflicts on classes in different namespaces.

### Changed

- Use configuration class in in web UI dropdown menu.

## 1.1.2

### Added

- Added `UltraSettings::ApplicationView` which can be used to embed the web UI application showing the configuration inside your own templates. So now you can more seamlessly integrate the settings UI into your own admin tools.

## 1.1.1

### Added

- Support for deep linking to a specific configuration section in the web UI. This is done by adding a query fragment to the URL matching the configuration name.

### Changed

- Changed the title on the Web UI to "Application Configuration" to better match the semantics of configuration objects.

## 1.1.0

### Added

- Revamped web UI that can now display setting values.
- Added option to specify fields as a secret in the configuration to prevent exposing sensitive information in the web interface. By default all fields are considered secrets. This can be changed per configuration by setting the `fields_secret_by_default` property to `false`.
- Added `UltraSettings::ConfigurationView` which can be used to embed the HTML table showing the configuration options and values inside other admin views. So now you can more seamlessly integrate the settings view into your own admin tools.
- Add `__to_hash__` method to `UltraSettings::Configuration` which can to serialize the current configuration values as a hash. This value can be used for comparing configuration between environments.

## 1.0.1

### Added
- Optimize object shapes for the Ruby interpreter by declaring instance variables in constructors.

## 1.0.0

### Added
- Initial release.
