module Services
  class Base
    def self.call(**args)
      new(**args).call
    end
  end
end