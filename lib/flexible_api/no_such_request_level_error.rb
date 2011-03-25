module FlexibleApi

  class NoSuchRequestLevelError < StandardError

    def initialize(rl_name, klass_name)
      @message = "There is no request level '#{rl_name}' for #{klass_name}"
    end

    def message
      @message
    end

  end

end
