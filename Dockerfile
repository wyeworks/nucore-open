FROM ruby:3.3.0 as base

WORKDIR /app
ENV BUNDLE_PATH /gems

# Install NodeJS based on https://github.com/nodesource/distributions#installation-instructions
ARG NODE_VERSION=setup_16.x
ENV NODE_VERISON ${NODE_VERSION}
RUN apt-get update && \
 # Installs the node repository
  apt-get install -y ca-certificates curl gnupg && \
  mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  NODE_MAJOR=16 && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
  apt-get update && \
  apt-get install nodejs -y && \
 # Installs libvips and the node repository
  apt-get install --yes libvips42 nodejs && \
  apt-get install npm -y
RUN npm install --global yarn && \
 apt-get autoremove -y

# Copy just what we need in order to bundle
COPY Gemfile Gemfile.lock .ruby-version /app/
# We reference the engines in the Gemfile, so we need them to be there, too
COPY vendor/engines /app/vendor/engines

# Install Bundler 2
RUN gem install bundler --version=$(cat Gemfile.lock | tail -1 | tr -d " ")

# Build bundle
RUN bundle install

# Copy application code base into image
COPY . /app

RUN cp config/database.yml.mysql.template config/database.yml && \
  cp config/secrets.yml.template config/secrets.yml

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-p", "3000"]

FROM base as develop

ENTRYPOINT ["./docker-entrypoint.sh"]

FROM base as deploy

ENV RAILS_ENV production
ARG RAILS_HOST
ENV RAILS_HOST ${RAILS_HOST}
RUN bundle install --without=development test
RUN yarn install

# asset compile
RUN SECRET_KEY_BASE=fake bundle exec rake assets:precompile
