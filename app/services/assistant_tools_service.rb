# frozen_string_literal: true

class AssistantToolsService
  class << self
    def register_tools(selected_tool_types = [])
      tools = default_tools
      tools.concat(network_tools(selected_tool_types))
      tools.concat(knowledge_tools(selected_tool_types))
      tools.flatten.compact
    end

    def parse_tool_types(selected_tools)
      return [] if selected_tools.blank?

      if selected_tools.is_a?(String)
        JSON.parse(selected_tools) rescue []
      elsif selected_tools.is_a?(Array)
        selected_tools
      else
        []
      end
    end

    private

    def default_tools
      [ Langchain::Tool::Calculator.new,
      Langchain::Tool::FileSystem.new ]
    end

    def network_tools(selected_tool_types)
      return [] unless selected_tool_types.include?("network")

      api_key = Rails.application.credentials.dig(:tools, :tavily_key)
      if api_key.present?
        [ Langchain::Tool::Tavily.new(api_key: api_key) ]
      else
        Rails.logger.warn("未找到 Tavily API 密钥，无法添加网络搜索工具")
        []
      end
    end

    def knowledge_tools(selected_tool_types)
      return [] unless selected_tool_types.include?("knowledge")

      [ Langchain::Tool::KnowledgeBase.new ]
    end
  end
end
