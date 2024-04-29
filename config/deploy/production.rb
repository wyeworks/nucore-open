# frozen_string_literal: true

set :branch, ENV["CIRCLE_SHA1"] || ENV["REVISION"] || ENV["BRANCH_NAME"] || "master"
set :rails_env, "production"

# prod-01 is down at the moment
# server "ials-core-web-prod-01.it.umass.edu", user: "corum", roles: %w(web app)
server "ials-core-web-prod-02.it.umass.edu", user: "corum", roles: %w(web app db)
set :deploy_to, "/home/corum/corum.umass.edu"
