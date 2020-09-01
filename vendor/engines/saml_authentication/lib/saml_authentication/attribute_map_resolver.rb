module SamlAuthentication

  class AttributeMapResolver < DeviseSamlAuthenticatable::DefaultAttributeMapResolver

    def attribute_map
      Settings.saml.attribute_map.to_h.stringify_keys
    end

  end

end
