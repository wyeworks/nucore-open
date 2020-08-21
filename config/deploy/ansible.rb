# frozen_string_literal: true

set :branch, ENV["CIRCLE_SHA1"] || ENV["REVISION"] || ENV["BRANCH_NAME"] || "master"
set :rails_env, "staging"

server "localhost", user: "corum", port: "2222", roles: %w(web app db)
set :deploy_to, "/home/corum/nucore.stage.tablexi.com"
