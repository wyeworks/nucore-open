FROM ruby:2.1

ENV RAILS_ENV development
RUN apt-get update --fix-missing
RUN apt-get install -y cron
RUN mkdir /app

WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
ADD vendor/engines /app/vendor/engines
RUN bundle install --without oracle

ADD . /app
