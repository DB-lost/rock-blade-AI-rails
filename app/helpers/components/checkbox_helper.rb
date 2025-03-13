module Components::CheckboxHelper
  def render_checkbox(label:, name:, **options)
    data_attrs = options.delete(:data) || {}
    button_data = options.delete(:button_data) || {}
    label_data = options.delete(:label_data) || {}

    render "components/ui/checkbox",
           name: name,
           label: label,
           data: data_attrs,
           button_data: button_data,
           label_data: label_data,
           options: options
  end
end
