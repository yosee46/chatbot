# frozen_string_literal: true

module Chatbot
  class CandidateChatbotScenarioOption
    attr_reader :state_params

    def initialize(chatbot_scenario_option, params)
      @chatbot_scenario_option = chatbot_scenario_option

      @state_params = chatbot_scenario_option.saving_state_params
      params.each do |key, value|
        @state_params = JSON.parse(HtmlUtils.all_convert_tag(@state_params.to_json, "\#\{#{key}\}", value))
      end
    end

    def content
      @chatbot_scenario_option.content
    end

    def id
      @chatbot_scenario_option.id
    end

    def html_content
      @html_content.nil? ? @chatbot_scenario_option.html_content_template : @html_content
    end

    def convert(params)
      html_content = html_content()
      return if html_content.nil?
      params.each do |key, value|
        html_content = HtmlUtils.all_convert_tag(html_content, "\#\{#{key}\}", value)
      end
      @html_content = html_content
      html_content
    end
  end
end
