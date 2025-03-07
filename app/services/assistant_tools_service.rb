# frozen_string_literal: true

class AssistantToolsService
  def self.register_tools
    [ Langchain::Tool::Calculator.new ]
  end
end
