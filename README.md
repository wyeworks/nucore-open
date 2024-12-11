# Corum (NUcore - UMass)

University of Massachusetts Amherst fork of NUCore Core Facility Management Software.

Forked from https://github.com/tablexi/nucore-open

[UMass Specific Integrations](vendor/engines/umass_corum/README.md)

## UMass Environments

| Domain               | Server                             | Deployment             | RAILS_ENV  |
| -------------------- | ---------------------------------- | -----------------------| ---------- |
| corum.umass.edu      | ials-core-web-prod-01.it.umass.edu | cap production deploy  | production |
| corum.umass.edu      | ials-core-web-prod-02.it.umass.edu | cap production deploy  | production |
| corum-test.umass.edu | ials-core-web-test-01.it.umass.edu | cap staging deploy     | staging    |
| corum-dev.umass.edu  | ials-core-web-dev-01.it.umass.edu  | cap development deploy | staging    |

Notes:
* _You must be on the UMass VPN in order to access the Dev and Test sites, as well as to SSH to any of the servers_
* _UMass requested a "development" environment, which we will be treating as a staging
environment, but will likely have more experimental data._
* _They called what we would call staging "test"_
* We're using "staging" as the `RAILS_ENV` to avoid confusion with Rails's environments

See [`ansible`](ansible/README.md) for our configuration-as-code for the servers.

[Additional information on UMass specific features](vendor/engines/umass_corum/README.md)

## NUCore Open Environment

TXI has been maintaining and developing NUCore since 2011.
We host a demo app on heroku:
https://nucore-open.herokuapp.com

NOTE: The recurring tasks background process is not running on the demo app.

## Note for School-specific Repos

As you pull in new features/bug fixes from open, please keep up with the [CHANGELOG](CHANGELOG.md)
to see changes that may break your school-specific repo and optional/required rake tasks you may want
to run.

[**See coding_standards.md**](doc/coding_standards.md) for more information on recommended strategies for customizing NUCore for a specific school.

[**See HOWTO_related_repos.md**](doc/HOWTO_related_repos.md) for more information on merging changes from the open source repo and deployment processes.

## Quickstart

Welcome to NUcore! This guide will help you get a development environment up and running.

### Development within Docker Environment

We recommend running within a docker environment.
Benefits:
- All daemons, processes are running at all times (easier to develop features)

To do this:
1. [Install Docker and Docker Compose](https://docs.docker.com/docker-for-mac/install/)
1. Run `./docker-setup.sh`. This sets up your `database.yml` and `secrets.yml` files. It also does an intial `bundle install`.
1. The output of the previous set is a randomly generated secret. Copy and paste it into your `secrets.yml` file as the `secret_key_base`.
1. This will also finish setting up the database
1. Seed the database with demo data (optional) `docker-compose run app bundle exec rake demo:seed`
1. Run `docker-compose up`
1. Open http://localhost:3000

If you seeded the demo data, you can log in with admin@example.com/P@ssw0rd!!

#### Email

We use [mailcatcher](https://mailcatcher.me/) as an SMTP server and web client. Visit <http://localhost:1080>.

#### Useful Commands

* **Rails Console:** `docker-compose exec app bundle exec rails c`
* **Command line in the container:** `docker-compose exec app bash`
* **Running tests:** Get a command line in the container and `bundle exec rspec`

### Development locally

It makes a few assumptions:

1. You write code on a Mac.
2. You have a running Oracle or MySQL instance with two brand new databases. (Oracle setup instructions [here](doc/HOWTO_oracle.md).)
3. You have the following installed:
    * [Ruby](http://www.ruby-lang.org/en)
    * [NodeJS](https://nodejs.org/en/)
    * [Bundler](http://gembundler.com)
    * [Git](http://git-scm.com)
    * [PhantomJS](http://phantomjs.org/)

### Spin it up

1. Download the project code from Github

    ```
    git clone git@github.com:tablexi/nucore-umass.git nucore-umass
    ```

2. Install dependencies

    ```
    cd nucore-umass
    bundle install
    ```

3. Configure your databases

    ```
    # For oracle, use config/database.yml.oracle.template
    cp config/database.yml.mysql.template config/database.yml
    ```

    Edit the adapter, database, username, and password settings for both the development and test DBs to match your database instance

4. Configure your secrets

  ```
  cp config/secrets.yml.template config/secrets.yml
  rake secret
  ```

  - Paste the output from `rake secret` into `config/secrets.yml` for both `development/secret_key_base` and `test/secret_key_base`

5. Set up databases

    ```
    rake db:create
    rake db:schema:load
    rake db:seed
    ```

_Known issue: if you run `db:setup` or all three in one rake command, the next time you run `db:migrate`, you will receive a `Table 'splits' already exists` error. Use the separate commands instead._

6. Seed your development database

    ```
    rake demo:seed
    ```

7. Configure your file storage

    By default, files are stored on the local filesystem. If you wish to use
    Amazon's S3 or Microsoft's Azure Blob Storage instead, see below.

    ### Amazon S3 (via Paperclip)
    Enable S3 in your environment by updating the local settings override file such as
    `config/settings/development.local.yml` or `config/settings/production.local.yml`.
    Uncomment the section under `paperclip`:
    ```
    paperclip:
      aws_access_key_id: <%= ENV.fetch("AWS_ACCESS_KEY", "Your-Key-Here") %>
      aws_secret_access_key: <ENV.fetch("AWS_SECRET_ACCESS_KEY", "Your-Key-Here") %>
      ...
    ```
    Then add your credentials to the ENV or `secrets.yml`.

    See [`migrating_to_s3.md`](./doc/migrating_to_s3.md) for more info.

    ### Microsoft Azure Blob Storage (via Active Storage)

    Enable Active Storage in your environment by updating the  `settings.yml` file with:
    ```
    features:
      active_storage: true
    ```

    In your gemfile, uncomment:
    `gem "azure-storage-blob", "~> 2.0", require: false`

    Environment files need to be updated as well (`development.rb`, `production.rb`):
    `config.active_storage.service = :azure`

    In `storage.yml`, uncomment the azure section:

    ```
    azure:
      service: AzureStorage
      storage_account_name: <%= Rails.application.secrets.dig(:active_storage, :azure, :storage_account_name) %>
      storage_access_key: <%= Rails.application.secrets.dig(:active_storage, :azure, :storage_access_key) %>
      container: <%= Rails.application.secrets.dig(:active_storage, :azure, :container) %>
    ```

    Then add your credentials to the ENV or `secrets.yml`.

8. Start your server

    ```
    bin/rails s
    ```

9. Log in

    Visit http://localhost:3000

    `demo:seed` creates several users with various permissions. All users have the default password of `"P@ssw0rd!!"`

    | Email/username     | Role |
    | ------------------ | ---- |
    | admin@example.com  | Admin|
    | ppi123@example.com | PI   |
    | sst123@example.com | Normal User (Example Facility) |
    | ast123@example.com | Facility Staff (Example Facility) |
    | ddi123@example.com | Facility Director (Example Facility) |
    | sst456@example.com | Normal User (Second Facility) |
    | ddi456@example.com | Facility Director (Second Facility) |

10. Play around! You're running NUcore!

11. Run `delayed_job` to support in-browser email previews.

    Run delayed jobs indefinitely in the background:
    ```
    ./script/delayed_job start
    ```

    Or run delayed jobs once for one-off jobs:
    ```
    ./script/delayed_job run
    ```

### Test it

NUcore uses [Rspec](http://rspec.info) to run tests. Try any of the following from NUcore's root directory.

* To run all tests (this will take awhile!)

    ```
    rake spec
    ```

* To run just the model tests

    ```
    rake spec:models
    ```

* To run just the controller tests
    ```
    rake spec:controllers
    ```

* To run just the javascript tests
    ```
    bundle exec rake teaspoon
    ```
    ... or to run with docker, first set ENV variables in `docker-compose.yml`:
    ```
    # Uncomment below to run teaspoon tests
    - RAILS_ENV=test
    - TEASPOON_RAILS_ENV=test
    ```
    ... and then:
    ```
    docker compose run app bundle exec rake teaspoon
    ```

#### Github Actions

To use Github Actions for CI testing you may need to maintain a testing image with specific versions of dependencies set.  To do this:
```
# Set your desired version of node and bundler
export NODE_VERSION=setup_16.x
export BUNDLER_VERSION=2.3.11

# Build the image
docker build . -f Dockerfile.github-actions --build-arg NODE_VERSION=$NODE_VERSION --build-arg BUNDLER_VERSION

# Check the IMAGE ID
docker image ls

# Tag the image with the appropriate ruby version
docker tag {IMAGE ID} wyeworkshub/ruby-node-chrome-pack:3.3.0

# Check the image was tagged correctly
docker image ls

# login and push the new tag
docker login
docker push wyeworkshub/ruby-node-chrome-pack:3.3.0
```

#### Parallel Tests

You can run specs in parallel during local development using the [`parallel_tests`](https://github.com/grosser/parallel_tests) gem.

* Create additional databases:

    ```
    rake parallel:create
    ```

* Run migrations (only needed if building from scratch):

    ```
    rake parallel:create
    ```

  OR

    ```
    rake parallel:load_schema
    ```

* Copy development schema (repeat after migrations):

	```
    rake parallel:prepare
	```

* Run tests:

    ```
    rake parallel:spec
    ```

* Example RegEx patterns:

	```
    rake parallel:spec[^spec/requests] # every spec file in spec/requests folder
    rake parallel:spec[user]  # run users_controller + user_helper + user specs
    rake parallel:spec['user|instrument']  # run user and product related specs
    rake parallel:spec['spec\/(?!features)'] # run RSpec tests except the tests in spec/features
    ```
* ZSH users may need to run it with the brackets escaped, like this:

    ```
      bundle exec rake parallel:spec\['spec\/(?!features)'\]
    ```

### Deprecation Toolkit

It is possible to track deprecation warnings locally with [deprecation_toolkit](https://github.com/Shopify/deprecation_toolkit). If you set the `RECORD_DEPRECATIONS` environment variable, `deprecation_toolkit` will collect deprecation warnings in YAML files in the `deprecations/` folder when specs are run.

`deprecation_toolkit` is configured in [`spec/deprecation_toolkit_env.rb`](spec/deprecation_toolkit_env.rb).

## Optional Modules

The following modules are provided as optional features via
[Rails engines](http://guides.rubyonrails.org/engines.html). These are enabled
by adding the appropriate engine to your Gemfile (all are on by default). They
exist in the `vendor/engines` directory.

* Accept Credit Cards & Purchase Orders (c2po)
* Connect to Dataprobe Power Relays (dataprobe)
* Link orders together as a Project (projects)
* [Sanger Sequencing order form and well plate management](vendor/engines/sanger_sequencing/README.md)
* [Split charges between different accounts](vendor/engines/split_accounts/README.md)
* [Authenticate against an LDAP server](vendor/engines/ldap_authentication/README.md)
* [Authenticate with SSO via SAML](vendor/engines/saml_authentication/README.md)

Engine-specific migrations should live in the engine's `db/migrate` directory and
use an engine initializer to add that path to the list of paths Rails checks. If
you need to disable an engine, you can undo all of the engine's migrations with
the `rake engines:db:migrate_down[ENGINE_NAME]` task.

## Learn more

There are valuable resources in the NUcore's doc directory.

* Want to conform to the project's established coding standards? [**See coding_standards.md**](doc/coding_standards.md)

* Want to know more about the instrument pricing model? [**See instrument_pricing.md**](doc/instrument_pricing.md)

* Need to move changes between nucore-open and your school-specific repo? [**See HOWTO_related_repos.md**](doc/HOWTO_related_repos.md)

* Need help getting Oracle running on your Mac? [**See HOWTO_oracle.md**](doc/HOWTO_oracle.md)

* Want to authenticate users against your institution's LDAP server? [**See the `ldap_authentication` engine**](vendor/engines/ldap_authentication/README.md)

* Need to use a 3rd party service with your NUcore? [**See HOWTO_external_services.txt**](doc/HOWTO_external_services.md)

* Need to asynchronously monitor some aspect of NUcore? [**See HOWTO_daemons.txt**](doc/HOWTO_daemons.txt)

* Want to integrate with Form.io? [**See form.io_tips_and_tricks**](doc/form.io_tips_and_tricks.docx)
