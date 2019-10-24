set :branch, ENV["CIRCLE_SHA1"] || ENV["REVISION"] || ENV["BRANCH_NAME"] || "ansible"
set :rails_env, "stage"

server "ials-core-web-dev-01.it.umass.edu", user: "nucore", roles: %w(web app db)
set :deploy_to, "/home/nucore/corum-dev.umass.edu"
