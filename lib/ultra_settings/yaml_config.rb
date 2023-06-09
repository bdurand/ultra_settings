# frozen_string_literal: true

module UltraSettings
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
