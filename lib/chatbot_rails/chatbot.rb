# frozen_string_literal: true

module Chatbot
  class Chatbot
    require 'singleton'
    include Singleton

    def start_conversation(conversation)
      return nil if conversation.nil?

      if conversation.conversation_session_id.nil?
        active_session_conversation = get_active_session_conversation(conversation.user_id)

        if active_session_conversation.present?
          conversation.conversation_session_id = active_session_conversation.conversation_session_id
        end
      end

      conversation.save
    end

    def get_active_session_conversation(user_id)
      chatbot_conversation = ChatbotConversation.find_latest(user_id)
      conversation = nil
      # 10分以内ならセッション有効
      if chatbot_conversation.present? && chatbot_conversation.updated_at >= DateTime.now - 10.minutes
        conversation = Conversation.fetch_new(self, chatbot_conversation.id, chatbot_conversation)
      end
      conversation
    end

    def get_conversation(user_id, conversation_session_id)
      chatbot_conversation = ChatbotConversation.find_latest_in_session(user_id, conversation_session_id)
      conversation = nil
      if chatbot_conversation.present?
        conversation = Conversation.fetch_new(self, chatbot_conversation.id, chatbot_conversation)
      end
      conversation
    end

    def get_conversations(user_id, conversation_session_id)
      chatbot_conversations = ChatbotConversation.find_all_in_session(user_id, conversation_session_id)
      conversations = []
      if chatbot_conversations.present?
        chatbot_conversations.sort_by(&:created_at).each do |chatbot_conversation|
          conversations.push(Conversation.fetch_new(self, chatbot_conversation.id, chatbot_conversation))
        end
      end
      conversations
    end

    def find_root_conversation(user_id, path_group_alias)
      chatbot_scenario_path_group = ChatbotScenarioPathGroup.find_by_group_alias(path_group_alias)
      chatbot_scenario_paths = ChatbotScenarioPath.find_root_path_by_path_group_id(chatbot_scenario_path_group.id)
      chatbot_scenario_path = retrieve_scenario_path(chatbot_scenario_paths)
      Conversation.new(self, user_id, chatbot_scenario_path.id)
    end

    def get_next_conversation(conversation)
      return nil unless conversation.finished?

      scenario_paths = ChatbotScenarioPath.find_by_parent_chatbot_scenario_path_id_and_option_id(conversation.chatbot_scenario_path_id, conversation.chatbot_scenario_option_id)
      if scenario_paths.nil?
        # TODO: 最初に戻る
        return nil
      end

      active_scenario_paths = []
      scenario_paths.each do |scenario_path|
        if scenario_path.delivery_status == 'active'
          active_scenario_paths.push(scenario_path)
        end
      end

      return nil if active_scenario_paths.empty?

      scenario_path = retrieve_scenario_path(active_scenario_paths)
      Conversation.new(self, conversation.user_id, scenario_path.id, conversation.chatbot_conversation_id, nil, conversation.conversation_session_id, conversation.state_params)
    end

    def save(args)
      ChatbotConversation.save_storage(args)
    end

    def update(args)
      ChatbotConversation.update_storage(args)
    end

    def update_review(args)
      ChatbotConversation.update_review(args)
    end

    private

    def retrieve_scenario_path(chatbot_scenario_paths)
      chatbot_scenario_paths.sample
    end
  end
end
