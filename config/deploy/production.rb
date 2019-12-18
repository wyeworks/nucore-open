# frozen_string_literal: true

set :branch, ENV["CIRCLE_SHA1"] || ENV["REVISION"] || ENV["BRANCH_NAME"] || "master"
set :rails_env, "production"

server "ials-core-web-prod-01.it.umass.edu", user: "corum", roles: %w(web app db)
server "ials-core-web-prod-02.it.umass.edu", user: "corum", roles: %w(web app)
set :deploy_to, "/home/corum/corum.umass.edu"
