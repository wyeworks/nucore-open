# frozen_string_literal: true

Spring.after_fork { FactoryBot.reload }

%w[
  .ruby-version
  .rbenv-vars
  tmp/restart.txt
  tmp/caching-dev.txt
].each { |path| Spring.watch(path) }
