# frozen_string_literal: true

module UltraSettings
  # Helper class to load YAML configuration files. Any ERB markup in the YAML
  # file will be evaluated. The YAML file should be structured like this:
  #
  # ```yaml
  # shared:
  #   foo: bar
  #   bar: baz
  #
  # development:
  #   bar: qux
  #   biz: buz
  #
  # test:
  #   bar: qix
  #   biz: biz
  # ```
  #
  # The section with the key matching the environment name is merged into
  # the shared section. In this example, the development environment would
  # have the following configuration:
  #
  # ```ruby
  # {
  #   "foo" => "bar",
  #   "bar" => "qux",
  #   "biz" => "buz"
  # }
  # ```
  #
  # In addition, the keys are flattened into a one level deep hash with dots
  # separating the keys.
  class YamlConfig
    def initialize(path, environment)
      yaml = load_yaml(path)
      @config = environment_config(yaml, environment)
    end

    def to_h
      @config
    end

    private

    def load_yaml(path)
      yaml = File.read(path)

      if yaml.include?("<%")
        yaml = ERB.new(yaml).result
      end

      hash = YAML.load(yaml) # rubocop:disable Security/YAMLLoad
      hash = {} unless hash.is_a?(Hash)
      hash
    end

    def environment_config(yaml, environment)
      shared = flatten_hash(yaml.fetch("shared", {}))
      env = flatten_hash(yaml.fetch(environment, {}))
      shared.merge(env)
    end

    def flatten_hash(hash, prefix = nil)
      hash.each_with_object({}) do |(key, value), result|
        key = key.to_s
        key = "#{prefix}.#{key}" if prefix

        if value.is_a?(Hash)
          result.merge!(flatten_hash(value, key))
        else
          result[key] = value
        end
      end
    end
  end
end
