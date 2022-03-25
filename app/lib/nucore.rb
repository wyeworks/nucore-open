# frozen_string_literal: true

module NUCore

  class PermissionDenied < RuntimeError
  end

  class Error < StandardError
  end

  class MixedFacilityCart < NUCore::Error
  end

  class NotPermittedWhileActingAs < NUCore::Error
  end

  class PurchaseException < NUCore::Error; end

end
