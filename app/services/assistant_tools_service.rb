# frozen_string_literal: true

class AssistantToolsService
  def self.register_tools
    [
      Langchain::Tool::Calculator.new,
      Langchain::Tool::Tavily.new(api_key: Rails.application.credentials.dig(:tools, :tavily_key))
    ]
  end
end
