FROM ruby:3.4.4 AS base

WORKDIR /app
ENV BUNDLE_PATH=/gems

# Update package lists and upgrade all packages
RUN apt-get update && apt-get upgrade -y && apt-get clean

# Install NodeJS based on https://github.com/nodesource/distributions#installation-instructions
ARG NODE_MAJOR=22
RUN curl -fsSL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -
RUN apt-get update && apt-get install --yes libvips42 nodejs
RUN npm install --global yarn

# Copy just what we need in order to bundle
COPY Gemfile Gemfile.lock .ruby-version /app/
# We reference the engines in the Gemfile, so we need them to be there, too
COPY vendor/engines /app/vendor/engines

# Install Bundler 2
RUN gem install bundler --version=$(cat Gemfile.lock | tail -1 | tr -d " ")

# Build bundle
RUN bundle install

RUN yarn install --non-interactive

# Copy application code base into image
COPY . /app

RUN cp config/database.yml.mysql.template config/database.yml && \
  cp config/secrets.yml.template config/secrets.yml

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-p", "3000"]

FROM base AS develop

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bin/dev"]

FROM base AS deploy

ENV RAILS_ENV=production
RUN bundle install --without=development test
# asset compile
RUN SECRET_KEY_BASE=fake bundle exec rake assets:precompile
