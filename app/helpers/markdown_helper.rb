module MarkdownHelper
  require "redcarpet"

  def markdown?(text)
    return false if text.blank?

    # 检查常见的 Markdown 特征
    markdown_patterns = [
      /^#+ /, # 标题
      /\[.+?\]\(.+?\)/, # 链接
      /`[^`]+`/, # 行内代码
      /```[\s\S]*?```/, # 代码块
      /\*\*.+?\*\*/, # 粗体
      /\*.+?\*/, # 斜体
      /^\s*[-*+] /, # 无序列表
      /^\s*\d+\. /, # 有序列表
      /^\s*>/, # 引用
      /\|.+\|.+\|/, # 表格
      /^-{3,}$/ # 分隔线
    ]

    markdown_patterns.any? { |pattern| text.match?(pattern) }
  end

  def markdown(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      link_attributes: { target: "_blank" }
    )

    markdown = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      underline: true,
      highlight: true,
      quote: true,
      footnotes: true
    )

    markdown.render(text).html_safe
  end
end
