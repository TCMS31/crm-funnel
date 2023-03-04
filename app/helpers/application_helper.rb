# frozen_string_literal: true

module ApplicationHelper
  BLANK_PLACEHOLDER = '—'

  # Inline error summary rendered above a form.
  def form_error_notification(object)
    return unless object.errors.any?

    tag.div(object.errors.full_messages.to_sentence, class: 'error-message', role: 'alert')
  end

  # Renders a value, or an em dash when there is nothing to show.
  def f_item(item)
    item.presence || BLANK_PLACEHOLDER
  end

  # Colour-coded pill for a funnel stage. `nil` means the deal has no history.
  def stage_badge(stage)
    name = stage.presence || 'Unstaged'
    tag.span(name, class: "badge badge--#{name.downcase}")
  end

  def nav_link_to(label, path)
    link_to label, path, class: "nav__link#{' nav__link--active' if current_page?(path)}"
  end
end
