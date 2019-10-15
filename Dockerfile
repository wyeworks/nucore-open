FROM ruby:2.5.5

# Install NodeJS based on https://github.com/nodesource/distributions#installation-instructions
RUN apt-get update
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash # Installs the node repository
RUN apt-get install --yes nodejs # Actually install NODEJS

# Cleanup
RUN apt-get autoremove -y

WORKDIR /app
ENV BUNDLE_PATH /gems

ENTRYPOINT ["./docker-entrypoint.sh"]
