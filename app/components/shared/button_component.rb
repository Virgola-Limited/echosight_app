module Shared
  class ButtonComponent <  ApplicationComponent
    def initialize(text:, url:, classes: nil)
      @text = text
      @url = url
      @classes = classes
    end

    def classes
      "#{@classes} px-5 py-3 text-base font-medium text-center text-blue-100 transition duration-150 ease-in-out bg-blue-500 rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-4 focus:ring-blue-300"
    end
  end
end