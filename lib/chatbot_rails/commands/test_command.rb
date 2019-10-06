# frozen_string_literal: true

class Chatbot::Commands::TestCommand < Chatbot::Commands::CommandBase
  def initialize
    super
    @input_param = ['test_id']
    @output_type = 'array'
    @output_param = %w[result_id]

    @description = '説明を入れる'
  end

  def execute(user_id, command_config)
    return nil unless validate(command_config, @input_param)

    test_id = command_config['test_id']

    @data

    output = []
    @data.each do |data|
      output.push('subscription_id' => data.result_id)
    end

    output if except(output)
  end
end
