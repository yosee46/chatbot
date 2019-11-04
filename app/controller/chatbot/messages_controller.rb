# frozen_string_literal: true

class Chatbot::MessagesController

  def new
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

  def index
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

end
