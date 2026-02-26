# frozen_string_literal: true

require "spec_helper"

require_relative "../../../yard_plugin/lib/yard-ultra_settings"

RSpec.describe UltraSettings::YARD::FieldHandler do
  before do
    YARD::Registry.clear
  end

  def parse_code(code)
    YARD::Parser::SourceParser.parse_string(code)
  end

  def find_method(class_name, method_name)
    YARD::Registry.at("#{class_name}##{method_name}")
  end

  describe "field documentation" do
    it "generates method documentation for string fields" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :name, type: :string, description: "The name field"
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "name")

      expect(method).not_to be_nil
      expect(method.signature).to eq("def name")
      expect(method.docstring.to_s).to eq("The name field")
      expect(method.tag(:return).types).to eq(["String, nil"])
    end

    it "generates method documentation for symbol fields" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :status, type: :symbol
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "status")

      expect(method).not_to be_nil
      expect(method.tag(:return).types).to eq(["Symbol, nil"])
    end

    it "generates method documentation for integer fields" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :count, type: :integer
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "count")

      expect(method).not_to be_nil
      expect(method.tag(:return).types).to eq(["Integer, nil"])
    end

    it "generates method documentation for float fields" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :price, type: :float
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "price")

      expect(method).not_to be_nil
      expect(method.tag(:return).types).to eq(["Float, nil"])
    end

    it "generates method documentation for boolean fields with ? suffix" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :enabled, type: :boolean, description: "Whether enabled"
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "enabled?")

      expect(method).not_to be_nil
      expect(method.signature).to eq("def enabled?")
      expect(method.docstring.to_s).to eq("Whether enabled")
      expect(method.tag(:return).types).to eq(["Boolean"])
    end

    it "generates method documentation for datetime fields" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :created_at, type: :datetime
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "created_at")

      expect(method).not_to be_nil
      expect(method.tag(:return).types).to eq(["Time, nil"])
    end

    it "generates method documentation for array fields" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :tags, type: :array
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "tags")

      expect(method).not_to be_nil
      expect(method.tag(:return).types).to eq(["Array<String>, nil"])
    end

    it "handles multiline descriptions" do
      code = <<~RUBY
                class UltraSettings::Configuration
                end

                class TestConfig < UltraSettings::Configuration
                  field :api_key, type: :string, description: "The API key for authentication.
        This should be kept secret."
                end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "api_key")

      expect(method).not_to be_nil
      expect(method.docstring.to_s).to eq("The API key for authentication.\nThis should be kept secret.")
    end
  end

  describe "return type with defaults" do
    it "does not include nil for fields with default values" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :timeout, type: :integer, default: 30
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "timeout")

      expect(method).not_to be_nil
      expect(method.tag(:return).types).to eq(["Integer"])
    end

    it "includes nil for fields with default_if condition" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :timeout, type: :integer, default: 30, default_if: :negative?
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "timeout")

      expect(method).not_to be_nil
      expect(method.tag(:return).types).to eq(["Integer, nil"])
    end

    it "includes nil for fields with default_if proc" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :port, type: :integer, default: 8080, default_if: ->(val) { val <= 0 }
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "port")

      expect(method).not_to be_nil
      expect(method.tag(:return).types).to eq(["Integer, nil"])
    end

    it "does not include nil for boolean fields even without defaults" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :active, type: :boolean
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "active?")

      expect(method).not_to be_nil
      expect(method.tag(:return).types).to eq(["Boolean"])
    end
  end

  describe "inheritance filtering" do
    it "only processes field methods in UltraSettings::Configuration subclasses" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class MyConfig < UltraSettings::Configuration
          field :foo, type: :string
        end

        class OtherClass
          field :bar, type: :string
        end
      RUBY

      parse_code(code)

      # Should document MyConfig#foo
      my_config_method = find_method("MyConfig", "foo")
      expect(my_config_method).not_to be_nil

      # Should NOT document OtherClass#bar
      other_class_method = find_method("OtherClass", "bar")
      expect(other_class_method).to be_nil
    end

    it "processes field methods in nested Configuration subclasses" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class BaseConfig < UltraSettings::Configuration
        end

        class DerivedConfig < BaseConfig
          field :setting, type: :string
        end
      RUBY

      parse_code(code)

      method = find_method("DerivedConfig", "setting")
      expect(method).not_to be_nil
      expect(method.tag(:return).types).to eq(["String, nil"])
    end
  end

  describe "integration with existing test configurations" do
    before do
      YARD::Registry.clear
      test_config_path = File.expand_path("../../test_configs/test_configuration.rb", __dir__)
      YARD::Parser::SourceParser.parse(test_config_path)
    end

    it "documents all fields from TestConfiguration" do
      # Check a few key fields
      foo_method = find_method("TestConfiguration", "foo")
      expect(foo_method).not_to be_nil
      expect(foo_method.docstring.to_s).to eq("An all purpose foo setting")
      expect(foo_method.tag(:return).types).to eq(["String, nil"])

      bool_method = find_method("TestConfiguration", "bool?")
      expect(bool_method).not_to be_nil
      expect(bool_method.tag(:return).types).to eq(["Boolean"])

      default_int_method = find_method("TestConfiguration", "default_int")
      expect(default_int_method).not_to be_nil
      expect(default_int_method.tag(:return).types).to eq(["Integer"])

      default_if_proc_method = find_method("TestConfiguration", "default_if_proc")
      expect(default_if_proc_method).not_to be_nil
      expect(default_if_proc_method.tag(:return).types).to eq(["Integer, nil"])
    end

    it "documents the correct number of field methods" do
      methods = YARD::Registry.all(:method).select { |m| m.namespace.path == "TestConfiguration" && m.name.to_s != "negative?" }
      # TestConfiguration has 21 field definitions
      expect(methods.count).to eq(21)
    end
  end

  describe "edge cases" do
    it "handles fields without descriptions" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :value
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "value")

      expect(method).not_to be_nil
      expect(method.docstring.to_s).to eq("")
      expect(method.tag(:return).types).to eq(["String, nil"])
    end

    it "handles fields with empty descriptions" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :value, description: ""
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "value")

      expect(method).not_to be_nil
      expect(method.docstring.to_s).to eq("")
    end

    it "defaults to string type when type is not specified" do
      code = <<~RUBY
        class UltraSettings::Configuration
        end

        class TestConfig < UltraSettings::Configuration
          field :name
        end
      RUBY

      parse_code(code)
      method = find_method("TestConfig", "name")

      expect(method).not_to be_nil
      expect(method.tag(:return).types).to eq(["String, nil"])
    end
  end
end
