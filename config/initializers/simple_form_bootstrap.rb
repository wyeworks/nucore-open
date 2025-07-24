# frozen_string_literal: true

# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  config.wrappers :bootstrap, tag: "div", class: "form-group", error_class: "has-error" do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: "control-label"
    b.use :maxlength
    b.wrapper tag: "div" do |ba|
      ba.use :input, class: "form-control"
      ba.use :error, wrap_with: { tag: "span", class: "help-block" }
      ba.use :hint,  wrap_with: { tag: "p", class: "help-block" }
    end
  end

  config.wrappers :prepend, tag: "div", class: "form-group", error_class: "has-error" do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: "control-label"
    b.wrapper tag: "div" do |input|
      input.wrapper tag: "div", class: "input-group" do |prepend|
        prepend.use :input, class: "form-control"
      end
      input.use :hint,  wrap_with: { tag: "span", class: "help-block" }
      input.use :error, wrap_with: { tag: "span", class: "help-block" }
    end
  end

  config.wrappers :append, tag: "div", class: "form-group", error_class: "has-error" do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: "control-label"
    b.wrapper tag: "div" do |input|
      input.wrapper tag: "div", class: "input-group" do |append|
        append.use :input, class: "form-control"
      end
      input.use :hint,  wrap_with: { tag: "span", class: "help-block" }
      input.use :error, wrap_with: { tag: "span", class: "help-block" }
    end
  end

  # Wrappers for forms and inputs using the Twitter Bootstrap toolkit.
  # Check the Bootstrap docs (http://twitter.github.com/bootstrap)
  # to learn about the different styles for forms and inputs,
  # buttons and other elements.
  config.default_wrapper = :bootstrap
end
