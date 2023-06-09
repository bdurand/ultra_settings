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

      YAML.safe_load(yaml, [Symbol, Date, Time], [], true)
    end

    def environment_config(yaml, environment)
      shared = yaml.fetch("shared", {})
      env = yaml.fetch(environment, {})
      shared.merge(env)
    end
  end
end
