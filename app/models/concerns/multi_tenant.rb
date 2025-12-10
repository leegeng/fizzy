module MultiTenant
  extend ActiveSupport::Concern

  class_methods do
    def accepting_signups?
      ENV.fetch("MULTI_TENANT", "false") == "true" || Account.none?
    end
  end
end
