module ChatbotRails
  class ControllersGenerator < Rails::Generators::Base

    CONTROLLERS = %w[chatbots messages sessions].freeze


    source_root File.expand_path("../../templates/controllers", __FILE__)
    argument :scope, required: true
    class_option :controllers, alias: "-c", type: :array

    def generate_controller
      @scope_prefix = scope.blank? ? '' : (scope.camelize + '::')
      controllers = options[:controllers] || CONTROLLERS
      controllers.each do |name|
        template "#{name}_controller.rb", "app/controllers/#{scope}/#{name}_controller.rb"
      end
    end
  end
end
