# frozen_string_literal: true

set :branch, ENV["CIRCLE_SHA1"] || ENV["REVISION"] || ENV["BRANCH_NAME"] || "master"
set :rails_env, "staging"

server "ials-core-web-test-01.it.umass.edu", user: "corum", roles: %w(web app db)
set :deploy_to, "/home/corum/corum-test.umass.edu"
