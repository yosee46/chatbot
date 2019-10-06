# frozen_string_literal: true

module Chatbot
  class Conversation
    attr_accessor :user_id, :conversation_session_id, :chatbot_scenario_path_group_id, :chatbot_scenario_path_id, :chatbot_scenario_option_id, :before_chatbot_conversation_id, :conversion, :chatbot_conversation_id, :state_params, :updated_at

    def initialize(chatbot, user_id = nil, chatbot_scenario_path_id = nil, before_chatbot_conversation_id = nil, chatbot_conversation_id = nil, conversation_session_id = nil, state_params = nil)
      @user_id = user_id
      @chatbot_scenario_path_id = chatbot_scenario_path_id
      @before_chatbot_conversation_id = before_chatbot_conversation_id
      @chatbot_conversation_id = chatbot_conversation_id
      @conversation_session_id = conversation_session_id
      @state_params = state_params
      fetch(chatbot)
    end

    def self.fetch_new(chatbot, chatbot_conversation_id, cache = nil)
      @chatbot_conversation_cache = cache
      new(chatbot, nil, nil, nil, chatbot_conversation_id)
    end

    def next_conversation
      return nil unless finished?
      @chatbot.get_next_conversation(self)
    end

    def finished?
      @chatbot_scenario_option_id.present?
    end

    def save
      @chatbot_conversation_cache = @chatbot.save(user_id: @user_id, conversation_session_id: @conversation_session_id, chatbot_scenario_path_id: @chatbot_scenario_path_id, chatbot_scenario_option_id: @chatbot_scenario_option_id, before_chatbot_conversation_id: @before_chatbot_conversation_id, conversion: @conversion, state_params: @state_params.nil? ? nil : @state_params.to_json)
      fetch(@chatbot)
      self
    end

    def update_review(review)
      @chatbot_conversation_cache = @chatbot.update_review(id: @chatbot_conversation_id, review: review)
      fetch(@chatbot)
      self
    end

    def update
      @chatbot_conversation_cache = @chatbot.update(id: @chatbot_conversation_id, conversation_session_id: @conversation_session_id, chatbot_scenario_option_id: @chatbot_scenario_option_id, conversion: @conversion, state_params: @state_params.nil? ? nil : @state_params.to_json)
      fetch(@chatbot)
      self
    end

    def ask_feedbacks(chatbot_scenario_option_id, state_params)
      @chatbot_scenario_feedbacks if @chatbot_scenario_feedbacks.present?

      select_from_candidates_for_chatbot_scenario_option(chatbot_scenario_option_id, state_params)
      @chatbot_scenario_feedbacks = get_chatbot_scenario_feedbacks
      @chatbot_scenario_feedbacks.each do |feedback|
        if feedback.feedback_type == 'command'
          # コマンド実装クラスのexecuteメソッドを実行
        end
      end

      @chatbot_scenario_feedbacks
    end

    def get_chatbot_scenario
      if @chatbot_scenario.nil?
        chatbot_scenario_path = ChatbotScenarioPath.find_by_id(@chatbot_scenario_path_id)
        @chatbot_scenario = chatbot_scenario_path.chatbot_scenario
        raise ActiveRecord::RecordNotFound if @chatbot_scenario.nil?
      end
      @chatbot_scenario
    end

    def get_chatbot_scenario_options
      if @chatbot_scenario_options.nil?
        scenario = get_chatbot_scenario
        @chatbot_scenario_options = ChatbotScenarioOption.find_by_chatbot_scenario_id(scenario.id)
      end
      @chatbot_scenario_options
    end

    def get_candidates_for_chatbot_scenario_option
      return @candidate_chatbot_scenario_options if @candidate_chatbot_scenario_options.present?

      @command_manager = Commands::CommandManager.instance

      chatbot_scenario_options = get_chatbot_scenario_options
      @candidate_chatbot_scenario_options = []
      chatbot_scenario_options.each do |chatbot_scenario_option|
        next unless @command_manager.check_candidate(chatbot_scenario_option, @user_id)
        candidates = @command_manager.generate_candidates(chatbot_scenario_option, user_id, @state_params)
        @candidate_chatbot_scenario_options.concat(candidates) if candidates.present?
      end
      @candidate_chatbot_scenario_options
    end

    def get_chatbot_scenario_option
      return nil unless finished?

      if @chatbot_scenario_option.nil?
        chatbot_scenario_options = get_chatbot_scenario_options
        chatbot_scenario_options.each do |chatbot_scenario_option|
          if chatbot_scenario_option.id == @chatbot_scenario_option_id
            @chatbot_scenario_option = chatbot_scenario_option
            return @chatbot_scenario_option
          end
        end
      end
      @chatbot_scenario_option
    end

    def get_chatbot_scenario_feedbacks
      if @chatbot_scenario_feedbacks.nil?
        chatbot_scenario_option = get_chatbot_scenario_option
        unless chatbot_scenario_option.nil?
          @chatbot_scenario_feedbacks = ChatbotScenarioFeedback.find_by_chatbot_scenario_option_id(chatbot_scenario_option.id).sort_by(&:order)
        end
      end

      if @chatbot_scenario_feedbacks.present?
        @chatbot_scenario_feedbacks.map do |chatbot_scenario_feedback|
          if chatbot_scenario_feedback.content_template.present? && @state_params.present?
            html_content = chatbot_scenario_feedback.content_template
            @state_params.each do |key, value|
              html_content = HtmlUtils.all_convert_tag(chatbot_scenario_feedback.content_template, "\#\{#{key}\}", value)
            end
            chatbot_scenario_feedback.content_template = html_content
          end
          chatbot_scenario_feedback
        end
      end

      @chatbot_scenario_feedbacks
    end

    def root_path?
      chatbot_scenario_path = ChatbotScenarioPath.find_by_id_or_fail(@chatbot_scenario_path_id)
      chatbot_scenario_path.parent_chatbot_scenario_path_id.nil?
    end

    private

    def fetch(chatbot)
      @conversion = 0
      @chatbot = chatbot

      unless @chatbot_scenario_path_id.nil?
        chatbot_scenario_path = ChatbotScenarioPath.find_by_id(@chatbot_scenario_path_id)
        @chatbot_scenario_path_group_id = chatbot_scenario_path.chatbot_scenario_path_group_id
      end

      if @chatbot_conversation_cache.nil? && @chatbot_conversation_id.nil?
        return
      end

      # TODO: データ層のインターフェースをchatbotクラスに隠蔽する
      if @chatbot_conversation_cache.nil? and @chatbot_conversation_id.present?
        @chatbot_conversation_cache = ChatbotConversation.find_by_id(@chatbot_conversation_id)
      end

      @conversation_session_id = @chatbot_conversation_cache.conversation_session_id
      @chatbot_scenario_path_id = @chatbot_conversation_cache.chatbot_scenario_path_id
      @chatbot_scenario_option_id = @chatbot_conversation_cache.chatbot_scenario_option_id
      @before_chatbot_conversation_id = @chatbot_conversation_cache.before_chatbot_conversation_id
      @conversion = @chatbot_conversation_cache.conversion
      @user_id = @chatbot_conversation_cache.user_id
      @updated_at = @chatbot_conversation_cache.updated_at
      @state_params = @chatbot_conversation_cache.state_params

      @chatbot_conversation_cache
    end

    def select_from_candidates_for_chatbot_scenario_option(chatbot_scenario_option_id, state_params = nil)
      if @chatbot_scenario_option.nil?
        chatbot_scenario_options = get_chatbot_scenario_options
        chatbot_scenario_options.each do |chatbot_scenario_option|
          next unless chatbot_scenario_option.id == chatbot_scenario_option_id
          @chatbot_scenario_option = chatbot_scenario_option
          @chatbot_scenario_option_id = chatbot_scenario_option_id

          @conversion = 1 if chatbot_scenario_option.conversion_flg?

          if chatbot_scenario_option.validate_state_params(state_params)
            @state_params = if @state_params.nil?
                              state_params
                            else
                              @state_params.merge(state_params)
                            end
          end

          update
        end

        raise ActiveRecord::RecordNotFound if @chatbot_scenario_option.nil?
      end
      @chatbot_scenario_option
    end
  end
end
