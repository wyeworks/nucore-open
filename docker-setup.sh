#!/bin/sh

cp -n config/database.yml.mysql.template config/database.yml
cp -n config/secrets.yml.template config/secrets.yml

docker-compose run app bundle install
docker-compose run app bundle exec rake secret
echo "Add this to secrets.yml as your secret_key_base"
echo ""
read -rsp $'Press any key once your secrets.yml is ready...\n' -n1 key

docker-compose run app bash -c "bundle exec rake db:create && bundle exec rake db:schema:load db:seed"
