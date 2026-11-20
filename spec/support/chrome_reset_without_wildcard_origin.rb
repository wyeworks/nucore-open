# frozen_string_literal: true

module ChromeResetWithoutWildcardOrigin
  private

  def execute_cdp(cmd, params = {})
    return super unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    super("Network.clearBrowserCookies")
    server = Capybara.current_session.server
    return unless server && params[:storageTypes].include?("local_storage")

    super(cmd, { origin: server.base_url, storageTypes: "local_storage" })
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeResetWithoutWildcardOrigin)
