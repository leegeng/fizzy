import { Turbo } from "@hotwired/turbo-rails"

Turbo.StreamActions.set_css_variable = function() {
  const name = this.getAttribute("name")
  const value = this.getAttribute("value")

  this.targetElements.forEach(element => element.style.setProperty(name, value))
}
