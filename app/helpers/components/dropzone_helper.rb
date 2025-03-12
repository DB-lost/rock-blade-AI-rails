module Components::DropzoneHelper
  def render_dropzone(upload_url: nil, file_param_name: nil, redirect_url: nil)
    render "components/ui/dropzone",
      upload_url: upload_url,
      file_param_name: file_param_name,
      redirect_url: redirect_url
  end
end
