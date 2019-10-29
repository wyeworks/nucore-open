# frozen_string_literal: true

set :branch, ENV["CIRCLE_SHA1"] || ENV["REVISION"] || ENV["BRANCH_NAME"] || "ansible"
set :rails_env, "staging"

server "localhost", user: "nucore", port: "2222", roles: %w(web app db)
set :deploy_to, "/home/nucore/nucore.stage.tablexi.com"
