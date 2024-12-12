class SanitizeHeadersMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    env["HTTP_ACCEPT"] = "*/*" if env["HTTP_ACCEPT"] =~ /(\.\.|{|})/

    @app.call(env)
  end
end
