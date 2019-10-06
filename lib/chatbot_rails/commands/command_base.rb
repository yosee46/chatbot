# frozen_string_literal: true

class Chatbot::Commands::CommandBase
  attr_reader :input_param, :output_param, :output_type, :command_alias

  def initialize
    @command_alias = self.class.name.split('::').last.underscore
    @input_param = []
    @output_type = ''
    @output_param = []
    @description = ''
  end

  def description
    "#{@description} （入力変数: #{@input_param.join(',')} / 出力変数: #{@output_param.join(',')} / 出力タイプ: #{@output_type}）"
  end

  def validate(payload, params)
    return true if payload.nil? || params.nil?
    keys = payload.keys
    params.all? { |param| keys.include? param }
  end

  def except(payload = {})
    if (@output_type == 'array' && payload.class != Array) || (@output_type != 'array' && payload.class == Array)
      return false
    end

    if payload.is_a?(FalseClass) || payload.is_a?(TrueClass)
      return @output_type == 'boolean'
    end

    if payload.class == Array
      return false if payload.empty?
      payload.all? do |item|
        validate(item, @output_param)
      end
    else
      validate(payload, @output_param)
    end
  end
end
