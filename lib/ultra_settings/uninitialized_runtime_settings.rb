# frozen_string_literal: true

module UltraSettings
  # This class is used to represent runtime settings that have not been initialized yet.
  # You can use this to protect your application from accidentally accessing runtime settings
  # before they are initialized. Doing this can cquse unexpected behavior if the runtime settings
  # engine has not yet been initialized. For instance, if your runtime settings enging reads from
  # a database it would not be available until the database connection is established.
  #
  # The intention of this class is to set it a the runtime settings at the beginning of initialization
  # and then set the actual runtime settings engine after the initialization is complete. It will
  # act as a guard to prevent invalid runtime settings backed configurations from being used during
  # initialization.
  #
  # @example
  #
  # UltraSettings.runtime_settings = UltraSettings::UninitializedRuntimeSettings
  # ActiveSupport.on_load(:active_record) do
  #   UltraSettings.runtime_settings = SuperSettings
  # end
  class UninitializedRuntimeSettings
    class Error < StandardError
    end

    class << self
      def [](key)
        raise Error.new("Attempt to call runtime setting #{key} during initialization")
      end
    end
  end
end
