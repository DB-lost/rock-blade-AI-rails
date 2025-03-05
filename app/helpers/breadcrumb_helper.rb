module BreadcrumbHelper
  def breadcrumbs
    @breadcrumbs ||= []
  end

  def add_breadcrumb(title, url = nil, options = {})
    breadcrumbs << {
      title: title,
      url: url,
      options: options
    }
  end

  def render_breadcrumbs
    return if breadcrumbs.empty?

    items = breadcrumbs.map.with_index do |crumb, index|
      is_last = index == breadcrumbs.length - 1

      if is_last
        content_tag(:span, crumb[:title], class: "text-sm font-medium")
      else
        safe_join([
          link_to(crumb[:title], crumb[:url], class: "text-sm text-muted-foreground hover:text-foreground"),
          svg_icon("chevron-right", class: "w-4 h-4 text-muted-foreground")
        ])
      end
    end

    safe_join(items)
  end

  private

  def svg_icon(name, options = {})
    case name
    when "chevron-right"
      content_tag(:svg, options.merge(
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor"
      )) do
        content_tag(:path, nil, d: "M9 18l6-6-6-6")
      end
    end
  end
end
