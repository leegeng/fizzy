module ApplicationHelper
  def page_title_tag
    tag.title @page_title || "Fizzy"
  end

  def icon_tag(name, aria: { hidden: true }, size: 24, **options)
    image_tag "#{name}.svg", aria: aria, size: size, **options
  end
end
