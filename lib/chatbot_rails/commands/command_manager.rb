# frozen_string_literal: true

class Chatbot::Commands::CommandManager
  require 'singleton'
  include Singleton

  attr_reader :commands

  def initialize
    @commands = [
      Chatbot::Commands::TestCommand.new
    ]
  end

  def find(command_alias)
    @commands.each do |command|
      return command if command.command_alias == command_alias
    end
    nil
  end

  def command_alias_descriptions
    @commands.map { |command| [command.description, command.command_alias] }
  end

  def generate_candidates(chatbot_scenario_option, user_id, state_params)
    candidate_chatbot_scenario_options = []
    variable_command_alias = chatbot_scenario_option.variable_command_alias
    if variable_command_alias.present?
      command = find(variable_command_alias)
      return if command.nil?

      command_outputs = command.execute(user_id, chatbot_scenario_option.command_config)
      return if command_outputs.nil?

      if command_outputs.class == Array
        command_outputs.each do |command_output|
          candidate_chatbot_scenario_option = ::Chatbot::CandidateChatbotScenarioOption.new(chatbot_scenario_option, command_output)
          candidate_chatbot_scenario_option.convert(command_output)
          candidate_chatbot_scenario_options.push(candidate_chatbot_scenario_option)
        end
      else
        candidate_chatbot_scenario_option = ::Chatbot::CandidateChatbotScenarioOption.new(chatbot_scenario_option, command_outputs)
        candidate_chatbot_scenario_option.convert(command_outputs)
        candidate_chatbot_scenario_options.push(candidate_chatbot_scenario_option)
      end
    else
      candidate_chatbot_scenario_option = ::Chatbot::CandidateChatbotScenarioOption.new(chatbot_scenario_option, [])
      candidate_chatbot_scenario_options.push(candidate_chatbot_scenario_option)
    end

    if state_params
      candidate_chatbot_scenario_options.map do |option|
        option.convert(state_params)
      end
    end

    candidate_chatbot_scenario_options
  end

  def check_candidate(chatbot_scenario_option, user_id)
    condition_command_alias = chatbot_scenario_option.condition_command_alias
    if condition_command_alias.present?
      command = find(condition_command_alias)
      return true if command.nil?

      command_result = command.execute(user_id, chatbot_scenario_option.command_config).to_s
      condition_value = chatbot_scenario_option.condition_value

      case chatbot_scenario_option.condition_operation
      when 'eq'
        command_result == condition_value
      when 'gt'
        command_result > condition_value
      when 'gte'
        command_result >= condition_value
      when 'lt'
        command_result < condition_value
      when 'lte'
        command_result <= condition_value
      when 'neq'
        command_result != condition_value
      else
        false
      end
    else
      true
    end
  end
end
