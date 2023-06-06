# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::Field do
  describe "value hierarchy" do
    let(:field) { UltraSettings::Field.new(name: "test", env_var: "foo", runtime_setting: "foo", yaml_key: "foo") }

    it "pulls a value from the environemnt variables by default" do
      expect(field.value(env: {"foo" => "env"}, settings: {"foo" => "setting"}, yaml_config: {"foo" => "yaml"})).to eq("env")
      expect(field.source(env: {"foo" => "env"}, settings: {"foo" => "setting"}, yaml_config: {"foo" => "yaml"})).to eq(:env)
    end

    it "pulls a value from the settings if the env var is not present" do
      expect(field.value(settings: {"foo" => "setting"}, yaml_config: {"foo" => "yaml"})).to eq("setting")
      expect(field.source(settings: {"foo" => "setting"}, yaml_config: {"foo" => "yaml"})).to eq(:settings)
    end

    it "pulls a value from the YAML config if there is no env var or setting" do
      expect(field.value(yaml_config: {"foo" => "yaml"})).to eq("yaml")
      expect(field.source(yaml_config: {"foo" => "yaml"})).to eq(:yaml)
    end

    it "does not use the YAML config if it does not exist" do
      expect(field.value).to be_nil
      expect(field.source).to eq(:default)
    end
  end

  describe "default" do
    it "uses the default value if no other value is present" do
      field = UltraSettings::Field.new(name: "foo", env_var: "foo", default: "bar")
      expect(field.value).to eq("bar")
    end

    it "does not use the default value if the value is false" do
      field = UltraSettings::Field.new(name: "foo", runtime_setting: "foo", type: :boolean, default: true)
      expect(field.value(settings: {"foo" => false})).to be false
    end

    it "uses the default value if the value is an empty string" do
      field = UltraSettings::Field.new(name: "foo", env_var: "foo", default: "bar")
      expect(field.value(env: {"foo" => ""})).to eq("bar")
    end

    it "coerces the default value to the specified type" do
      field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :integer, default: "1")
      expect(field.value).to eq 1
    end
  end

  describe "default_if" do
    it "uses the default only if the default_if block returns true" do
      field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :integer, default: "1", default_if: ->(val) { val < 0 })
      expect(field.value(env: {"foo" => "-1"})).to eq 1
    end

    it "does not use the default if the default_if block returns false" do
      field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :integer, default: "1", default_if: ->(val) { val < 0 })
      expect(field.value(env: {"foo" => "2"})).to eq 2
    end

    it "always uses the default if the default_if block is not present" do
      field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :integer, default: "1", default_if: ->(val) { val < 0 })
      expect(field.value(env: {"foo" => ""})).to eq 1
    end
  end

  describe "type" do
    describe "string" do
      it "coerces the value to a string" do
        field = UltraSettings::Field.new(name: "foo", yaml_key: "foo", type: :string)
        expect(field.value(yaml_config: {"foo" => 1})).to eq("1")
      end

      it "returns nil if the value is blank" do
        field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :string)
        expect(field.value(env: {"foo" => ""})).to be_nil
      end

      it "returns a frozen string" do
        field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :string)
        value = field.value(env: {"foo" => +"bar"})
        expect(value).to be_a String
        expect(value).to be_frozen
      end
    end

    describe "symbol" do
      it "coerces the value to a symbol" do
        field = UltraSettings::Field.new(name: "foo", yaml_key: "foo", type: :symbol)
        expect(field.value(yaml_config: {"foo" => "bar"})).to eq(:bar)
      end

      it "returns nil if the value is blank" do
        field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :symbol)
        expect(field.value(env: {"foo" => ""})).to be_nil
      end
    end

    describe "boolean" do
      it "coerces the value to a boolean" do
        field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :boolean)
        expect(field.value(env: {"foo" => "true", "bar" => "0"})).to be true

        field = UltraSettings::Field.new(name: "bar", env_var: "bar", type: :boolean)
        expect(field.value(env: {"foo" => "true", "bar" => "0"})).to be false
      end

      it "returns nil if the value is blank" do
        field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :boolean)
        expect(field.value(env: {"foo" => ""})).to be_nil
      end
    end

    describe "integer" do
      it "coerces the value to an integer" do
        field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :integer)
        expect(field.value(env: {"foo" => "1"})).to eq(1)
      end

      it "returns nil if the value is blank" do
        field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :integer)
        expect(field.value(env: {"foo" => ""})).to be_nil
      end
    end

    describe "float" do
      it "coerces the value to a float" do
        field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :float)
        expect(field.value(env: {"foo" => "1.1"})).to eq(1.1)
      end

      it "returns nil if the value is blank" do
        field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :float)
        expect(field.value(env: {"foo" => ""})).to be_nil
      end
    end

    describe "datetime" do
      it "coerces the value to a datetime" do
        field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :datetime)
        expect(field.value(env: {"foo" => "2015-01-01 12:01:50Z"})).to eq(Time.utc(2015, 1, 1, 12, 1, 50))
      end

      it "returns nil if the value is blank" do
        field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :datetime)
        expect(field.value(env: {"foo" => ""})).to be_nil
      end
    end

    describe "array" do
      it "coerces the value to an array of strings" do
        field = UltraSettings::Field.new(name: "foo", yaml_key: "foo", type: :array)
        expect(field.value(yaml_config: {"foo" => [1, 2, 3]})).to eq(["1", "2", "3"])
      end

      it "returns nil if the value is blank" do
        field = UltraSettings::Field.new(name: "foo", env_var: "foo", type: :array)
        expect(field.value(env: {"foo" => ""})).to be_nil
      end
    end
  end
end
