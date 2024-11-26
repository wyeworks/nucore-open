# frozen_string_literal: true

require "puma/acme"

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum, this matches the default thread size of Active Record.
#
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests, default is 3000.
#
port        ENV.fetch("PORT") { 3000 }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory. If you use this option
# you need to make sure to reconnect any threads in the `on_worker_boot`
# block.
#
# preload_app!

# The code in the `on_worker_boot` will be called if you are using
# clustered mode by specifying a number of `workers`. After each worker
# process is booted this block will be run, if you are using `preload_app!`
# option you will want to use this block to reconnect to any threads
# or connections that may have been created at application boot, Ruby
# cannot share connections between processes.
#
# on_worker_boot do
#   ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
# end

# Allow puma to be restarted by `rails restart` command.
# plugin :tmp_restart

if ENV["PUMA_ACME"] == "enable"
  # Config for ACME
  plugin :acme

  bind "tcp://0.0.0.0:80"
  bind ENV.fetch("ACME_BIND", "acme://0.0.0.0:443")

  # Account contact URL(s). For email, use the form 'mailto:user@domain.tld'.
  # Recommended for account recovery and revocation.
  acme_contact "mailto:itis-monitor@gmail.com"

  # Specify server names (SAN extension).
  acme_server_names "corum-dev.it.umass.edu", "www.corum-dev.it.umass.edu"

  # Enable automatic renewal based on an amount of time or fraction of life
  # remaining. For an amount of time, use Integer seconds, for example the value
  # 2592000 will set renewal to 30 days before certificate expiry. For a fraction
  # of life remaining, use a Float between 0 and 1, for example the value 0.75
  # will set renewal at 75% of the way through the certificate lifetime.
  acme_renew_at 0.75

  # URL of ACME server's directory URL, defaults to LetsEncrypt.
  acme_directory "https://acme.enterprise.sectigo.com"

  # Accept the Terms of Service (TOS) of an ACME server with the server's
  # directory URL as a string or true to accept any server's TOS.
  acme_tos_agreed true

  # External Account Binding (EAB) token KID & secret HMAC key for the ACME
  # server. See RFC 8555, Section 7.3.4 for details.
  acme_eab_kid      ENV["ACME_KID"]
  acme_eab_hmac_key ENV["ACME_HMAC_KEY"]

  # Encryption key algorithm, either :ecdsa or :rsa, defaults to :ecdsa.
  acme_algorithm :ecdsa

  # Provision mode, either :background or :foreground, defaults to :background.
  # Background mode provisions certificates in a background thread without
  # blocking binding or request serving for non-acme listeners.
  # Foreground mode blocks all binding listeners until a certificate
  # provisions, compatible only with zero-challenge ACME flow.
  acme_mode :background

  # ActiveSupport::Cache::Store compatible cache to store account, order, and
  # certificate data. Defaults to a local filesystem based cache.
  # acme_cache Rails.cache

  # Path to the cache directory for the default cache, defaults to 'tmp/acme'.
  acme_cache_dir "tmp/acme"

  # Time to wait in seconds before rechecking order status, defaults to 1 second.
  acme_poll_interval 1

  # Time to wait in seconds before checking for renewal, defaults to 1 hour.
  acme_renew_interval 60 * 60
end
