# frozen_string_literal: true

RSpec::Matchers.define :be_allowed_to do |action, object|
  description do
    "be allowed to #{action} " +
      if object.respond_to?(:model_name)
        object.model_name.human.pluralize
      elsif object.class.respond_to?(:model_name)
        "this #{object.class.model_name.human}"
      else
        "This #{object.class}"
      end.downcase
  end

  match do |ability|
    ability.can?(action, object)
  end
end

def it_is_allowed_to(actions, object = nil)
  Array(actions).each do |action|
    it "is allowed to #{action}" do
      target = object || yield
      expect(subject).to be_allowed_to(action, target)
    end
  end
end

def it_is_not_allowed_to(actions, object = nil)
  Array(actions).each do |action|
    it "is not allowed to #{action}" do
      target = object || yield
      expect(subject).not_to be_allowed_to(action, target)
    end
  end
end
