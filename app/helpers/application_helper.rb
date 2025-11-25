module ApplicationHelper
  def menu_item(name, path, **kwargs)
    is_match = request.path.match(/^#{path}/)
    "<a href='#{path}' class='item #{'active' if is_match}' #{kwargs.map { |k, v| "#{k}='#{v}'" }.join(' ')}>#{name}</a>".html_safe
  end
end
