# frozen_string_literal: true

class Api::Chatbot::ChatbotController < Api::ApplicationController
  before_action :setup_user
  protect_from_forgery

  def new
    path_group_alias = params[:path_group_alias]
    @bot = ::Chatbot::Chatbot.instance

    if path_group_alias.nil?
      @data = { message: 'invalid path_group_alias parameter' }
      return render 'api/errors/show', formats: 'json', status: 400
    end

    @user = ContextManager.get_user
    if @user.nil?
      @data = { message: 'authentication error' }
      return render 'api/errors/show', formats: 'json', status: 401
    end

    root_conversation = @bot.find_root_conversation(@user.id, path_group_alias)
    conversation = @bot.start_conversation(root_conversation)

    @conversation_session_id = conversation.conversation_session_id

    if conversation.present? && conversation.get_chatbot_scenario.present?
      @chatbot_scenario = conversation.get_chatbot_scenario
      @candidate_chatbot_scenario_options = conversation.get_candidates_for_chatbot_scenario_option
    end

    render 'api/chatbots/new', formats: 'json'
  end

  def message
    @conversation_session_id = params[:conversation_session_id]
    scenario_option_id = params[:chatbot_scenario_option_id]
    state_params = params[:state_params]
    @bot = ::Chatbot::Chatbot.instance

    @user = ContextManager.get_user
    if @user.nil?
      @data = { message: 'authentication error' }
      return render 'api/errors/show', formats: 'json', status: 401
    end

    conversation = @bot.get_conversation(@user.id, @conversation_session_id)
    if conversation.nil?
      @data = { message: 'conversation not found' }
      return render 'api/errors/show', formats: 'json', status: 400
    end

    if state_params.present?
      begin
        state_params = JSON.parse(state_params)
      rescue JSON::ParserError => e
        @data = { message: 'invalid state_params' }
        return render 'api/errors/show', formats: 'json', status: 400
      end
    end

    # ユーザの回答から返答を作成
    @chatbot_scenario_feedbacks = conversation.ask_feedbacks(scenario_option_id, state_params)
    @chatbot_scenario_option = conversation.finished? ? conversation.get_chatbot_scenario_option : nil

    # 次のquestionを作る
    # TODO endかどうかをconversationに持たせる、検索するのはchatbot
    @end_flg = true
    next_conversation = conversation.finished? ? @bot.start_conversation(conversation.next_conversation) : nil
    unless next_conversation.nil?
      @end_flg = false
      @next_chatbot_scenario = next_conversation.get_chatbot_scenario
      @next_candidate_chatbot_scenario_options = next_conversation.get_candidates_for_chatbot_scenario_option
    end

    render 'api/chatbots/message', formats: 'json'
  end

  def messages
    @conversation_session_id = params[:conversation_session_id]
    @user = ContextManager.get_user
    @bot = ::Chatbot::Chatbot.instance

    if @user.nil?
      @data = { message: 'authentication error' }
      return render 'api/errors/show', formats: 'json', status: 401
    end

    return render 'api/errors/show', formats: 'json', status: 401 if @user.nil?

    conversations_in_session = @bot.get_conversations(@user.id, @conversation_session_id)

    @conversations = []

    conversations_in_session.reverse_each do |conversation|
      @conversations.push(conversation)
      break if conversation.root_path?
    end
    @conversations.reverse!

    render 'api/chatbots/messages', formats: 'json'
  end

  def active_session
    @bot = ::Chatbot::Chatbot.instance
    @user = ContextManager.get_user

    if @user.nil?
      @data = { message: 'authentication error' }
      return render 'api/errors/show', formats: 'json', status: 401
    end

    conversation = @bot.get_active_session_conversation(@user.id)
    if conversation.present? && !conversation.finished?
      @conversation_session_id = conversation.conversation_session_id
    end

    render 'api/chatbots/session', formats: 'json'
  end

  def user_feedback
    @bot = ::Chatbot::Chatbot.instance
    @user = ContextManager.get_user

    @feedback_option = params[:feedback_option]
    if @feedback_option.nil?
      @data = { message: 'invalid feedback_option parameter' }
      return render 'api/errors/show', formats: 'json', status: 400
    end

    if @user.nil?
      @data = { message: 'authentication error' }
      return render 'api/errors/show', formats: 'json', status: 401
    end

    active_session_conversation = @bot.get_active_session_conversation(@user.id)
    if active_session_conversation.nil?
      @data = { message: 'conversation not found' }
      return render 'api/errors/show', formats: 'json', status: 400
    end

    active_session_conversation.update_review(@feedback_option)

    render 'api/chatbots/user_feedback', formats: 'json'
  end
end
