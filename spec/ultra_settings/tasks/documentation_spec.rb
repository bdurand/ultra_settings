# frozen_string_literal: true

require_relative "../../spec_helper"
require_relative "../../../lib/ultra_settings/tasks/documentation"

RSpec.describe UltraSettings::Tasks::Documentation do
  let(:documentation) { described_class.new(TestConfiguration) }

  describe "#yard_doc" do
    it "generates YARD doc for string field" do
      field = TestConfiguration.fields.find { |f| f.name == "foo" }
      result = documentation.yard_doc(field)
      expect(result).to eq("# @!attribute [r] foo\n# @return [String, nil]\n")
    end

    it "generates YARD doc for symbol field" do
      field = TestConfiguration.fields.find { |f| f.name == "symbol" }
      result = documentation.yard_doc(field)
      expect(result).to eq("# @!attribute [r] symbol\n# @return [Symbol, nil]\n")
    end

    it "generates YARD doc for integer field" do
      field = TestConfiguration.fields.find { |f| f.name == "int" }
      result = documentation.yard_doc(field)
      expect(result).to eq("# @!attribute [r] int\n# @return [Integer, nil]\n")
    end

    it "generates YARD doc for float field" do
      field = TestConfiguration.fields.find { |f| f.name == "float" }
      result = documentation.yard_doc(field)
      expect(result).to eq("# @!attribute [r] float\n# @return [Float, nil]\n")
    end

    it "generates YARD doc for boolean field" do
      field = TestConfiguration.fields.find { |f| f.name == "bool" }
      result = documentation.yard_doc(field)
      expect(result).to eq("# @!attribute [r] bool\n# @return [Boolean]\n")
    end

    it "generates YARD doc for datetime field" do
      field = TestConfiguration.fields.find { |f| f.name == "time" }
      result = documentation.yard_doc(field)
      expect(result).to eq("# @!attribute [r] time\n# @return [Time, nil]\n")
    end

    it "generates YARD doc for array field" do
      field = TestConfiguration.fields.find { |f| f.name == "array" }
      result = documentation.yard_doc(field)
      expect(result).to eq("# @!attribute [r] array\n# @return [Array<String>, nil]\n")
    end

    it "generates YARD doc for field with default value (no nil)" do
      field = TestConfiguration.fields.find { |f| f.name == "default_int" }
      result = documentation.yard_doc(field)
      expect(result).to eq("# @!attribute [r] default_int\n# @return [Integer]\n")
    end

    it "generates YARD doc for boolean field with default value" do
      field = TestConfiguration.fields.find { |f| f.name == "default_bool" }
      result = documentation.yard_doc(field)
      expect(result).to eq("# @!attribute [r] default_bool\n# @return [Boolean]\n")
    end

    it "generates YARD doc for field with default and default_if (includes nil)" do
      field = TestConfiguration.fields.find { |f| f.name == "default_if_proc" }
      result = documentation.yard_doc(field)
      expect(result).to eq("# @!attribute [r] default_if_proc\n# @return [Integer, nil]\n")
    end

    it "generates YARD doc for field with default and default_if method (includes nil)" do
      field = TestConfiguration.fields.find { |f| f.name == "default_if_method" }
      result = documentation.yard_doc(field)
      expect(result).to eq("# @!attribute [r] default_if_method\n# @return [Integer, nil]\n")
    end
  end

  describe "#defined_fields" do
    it "returns fields defined on the configuration class" do
      fields = documentation.defined_fields
      expect(fields).to be_an(Array)
      expect(fields).to all(be_a(UltraSettings::Field))
      expect(fields.map(&:name)).to include("foo", "bar", "baz", "int", "float", "bool", "time", "array", "symbol")
    end

    it "excludes fields from parent configuration class" do
      subclass_doc = described_class.new(SubclassConfiguration)
      fields = subclass_doc.defined_fields
      field_names = fields.map(&:name)

      # Should include fields defined in SubclassConfiguration
      expect(field_names).to include("sub")
      expect(field_names).to include("bar")  # Overridden field

      # Should not include fields from TestConfiguration parent that weren't overridden
      expect(field_names).not_to include("foo", "baz")
    end
  end

  describe "#field_location" do
    it "returns the source file and line number for a field method" do
      field = TestConfiguration.fields.find { |f| f.name == "foo" }
      path, line = documentation.field_location(field)
      expect(path).to be_a(String)
      expect(path).to end_with("test_configuration.rb")
      expect(line).to be_a(Integer)
      expect(line).to be > 0
    end

    it "returns the source file and line number for a boolean field method" do
      field = TestConfiguration.fields.find { |f| f.name == "bool" }
      path, line = documentation.field_location(field)
      expect(path).to be_a(String)
      expect(path).to end_with("test_configuration.rb")
      expect(line).to be_a(Integer)
      expect(line).to be > 0

      # Verify it's looking up the predicate method (bool?)
      method = TestConfiguration.instance_method(:bool?)
      expect([path, line]).to eq(method.source_location)
    end
  end

  describe "#sources_with_yard_docs" do
    it "returns a hash mapping file paths to updated content" do
      result = documentation.sources_with_yard_docs
      expect(result).to be_a(Hash)
      expect(result.keys).to all(be_a(String))
      expect(result.values).to all(be_a(String))
    end

    it "includes the source file for the configuration class" do
      result = documentation.sources_with_yard_docs
      test_config_path = result.keys.find { |path| path.end_with?("test_configuration.rb") }
      expect(test_config_path).not_to be_nil
    end

    it "inserts YARD documentation block after last field definition" do
      result = documentation.sources_with_yard_docs
      test_config_path = File.expand_path("../../test_configs/test_configuration.rb", __dir__)
      content = result[test_config_path]

      # Check that YARD docs are in a separate class definition
      expect(content).to include("# Begin autogenerated YARD docs")
      expect(content).to include("class TestConfiguration")
      expect(content).to include("# End autogenerated YARD docs")

      # YARD class should come at the end of the file
      expect(content).to match(/# Begin autogenerated YARD docs\nclass TestConfiguration\n.*?end\n# End autogenerated YARD docs\n\z/m)
    end

    it "inserts correct return types for all field types" do
      result = documentation.sources_with_yard_docs
      test_config_path = result.keys.find { |path| path.end_with?("test_configuration.rb") }
      content = result[test_config_path]

      expect(content).to include("# @return [String, nil]")
      expect(content).to include("# @return [Symbol, nil]")
      expect(content).to include("# @return [Integer, nil]")
      expect(content).to include("# @return [Float, nil]")
      expect(content).to include("# @return [Boolean]")
      expect(content).to include("# @return [Time, nil]")
      expect(content).to include("# @return [Array<String>, nil]")
    end

    it "includes @!attribute directives for each field" do
      result = documentation.sources_with_yard_docs
      test_config_path = result.keys.find { |path| path.end_with?("test_configuration.rb") }
      content = result[test_config_path]

      # Check for attribute directives
      expect(content).to match(/# @!attribute \[r\] foo\n\s*# @return \[String, nil\]/)
      expect(content).to match(/# @!attribute \[r\] int\n\s*# @return \[Integer, nil\]/)
      expect(content).to match(/# @!attribute \[r\] bool\n\s*# @return \[Boolean\]/)
    end

    it "handles fields with default values correctly (no nil)" do
      result = documentation.sources_with_yard_docs
      test_config_path = result.keys.find { |path| path.end_with?("test_configuration.rb") }
      content = result[test_config_path]

      # Fields with defaults should not have nil in return type
      expect(content).to include("# @!attribute [r] default_int")
      expect(content).to match(/# @!attribute \[r\] default_int\n\s*# @return \[Integer\]/)
      expect(content).to match(/# @!attribute \[r\] default_bool\n\s*# @return \[Boolean\]/)
    end

    it "handles multiple fields in the same file" do
      result = documentation.sources_with_yard_docs
      test_config_path = result.keys.find { |path| path.end_with?("test_configuration.rb") }
      content = result[test_config_path]

      # Count how many YARD attribute directives were inserted
      yard_doc_count = content.scan(/# @!attribute/).size
      field_count = documentation.defined_fields.size

      expect(yard_doc_count).to eq(field_count)
    end

    it "preserves existing file content structure" do
      result = documentation.sources_with_yard_docs
      test_config_path = result.keys.find { |path| path.end_with?("test_configuration.rb") }
      content = result[test_config_path]

      # Check that class definition and other content is still there
      expect(content).to include("class TestConfiguration < UltraSettings::Configuration")
      expect(content).to include("def negative?(val)")

      # Field definitions should still be present
      expect(content).to include('field :foo, description: "An all purpose foo setting"')
      expect(content).to include("field :int, type: :integer")
    end

    it "removes existing YARD docs before inserting new ones" do
      # First generate docs
      result1 = documentation.sources_with_yard_docs
      test_config_path = result1.keys.find { |path| path.end_with?("test_configuration.rb") }
      content_with_docs = result1[test_config_path]

      # Count YARD blocks
      begin_count = content_with_docs.scan("# Begin autogenerated YARD docs").size
      end_count = content_with_docs.scan("# End autogenerated YARD docs").size

      expect(begin_count).to eq(1)
      expect(end_count).to eq(1)

      # Simulate re-running on content that already has YARD docs
      # by temporarily stubbing File.read
      allow(File).to receive(:read).and_return(content_with_docs)

      result2 = documentation.sources_with_yard_docs
      content_regenerated = result2[test_config_path]

      # Should still only have one YARD block
      begin_count = content_regenerated.scan("# Begin autogenerated YARD docs").size
      end_count = content_regenerated.scan("# End autogenerated YARD docs").size

      expect(begin_count).to eq(1)
      expect(end_count).to eq(1)
    end

    context "with subclass configuration" do
      let(:documentation) { described_class.new(SubclassConfiguration) }

      it "only adds YARD docs for fields defined in the subclass" do
        result = documentation.sources_with_yard_docs
        subclass_config_path = result.keys.find { |path| path.end_with?("subclass_configuration.rb") }
        content = result[subclass_config_path]

        # Should have YARD doc class definition
        expect(content).to include("# Begin autogenerated YARD docs")
        expect(content).to include("class SubclassConfiguration")
        expect(content).to include("# End autogenerated YARD docs")

        # Should have docs for subclass fields only
        expect(content).to include("# @!attribute [r] sub")
        expect(content).to include("# @!attribute [r] bar")

        # Should not include documentation for parent class fields that aren't overridden
        expect(content).not_to include("@!attribute [r] foo")
        expect(content).not_to include("@!attribute [r] baz")
      end
    end
  end
end
