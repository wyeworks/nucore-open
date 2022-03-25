# Running Oracle in Development

Follow these instructions to set up the Oracle database to run in Docker, but the app itself in your native environment.

## Setting up the Oracle Server with Docker

### Set up Docker and Oracle Container Registry (for 19c)

1. Install Docker for Mac by running `brew cask install docker`
1. Sign up for an Oracle account at <https://container-registry.oracle.com/>. If you already have an Oracle account, you can skip this step and use your existing account.
1. Select "Database" from the list of containers, then select the enterprise repository.  **This page also includes some good general documentation.**
1. On the right hand side select your language and agree to the terms and services.
1. In your terminal, make sure that docker is logged in with your Oracle credentials by running `docker login container-registry.oracle.com`.

### Set up Docker and Docker Hub (for 12c)

1. Install Docker for Mac by running `brew cask install docker`
1. Sign up for a Docker Hub account at https://hub.docker.com/. If you already have a Docker Hub account, you can skip this step and use your existing account.
1. Go to https://store.docker.com/images/oracle-database-enterprise-edition and click the button **Proceed to Checkout**. Complete and submit the form in order to get access to the free container that Oracle provides.
1. In your terminal, make sure that you are logged in with your Docker Hub credentials by running `docker login`.

### Run an Oracle service using docker-compose

You can run Oracle via docker-compose service.  Here is an example of how you might set it up:

```yaml
# docker-compose.yaml

services:
  db:
    image: container-registry.oracle.com/database/enterprise:19.3.0.0

    ports:
      - "1521:1521"
    volumes:
      - db-data:/ORCL
    logging:
      driver: none
    stdin_open: true
    tty: true
```

To start the `db` service, run:

```
docker-compose up db
```

To stop the `db` service run:

```
docker-compose down
```

### Start an Oracle container

Alternately, you can run Oracle in a stand-alone docker container:

```
# Run the Oracle image as a container named oracle, storing data
# in the directory oracle/, which is ignored in git.
# When you run this for the first time, it will take a while to download
# the image and initialize the database.
#
# When the output in the terminal includes a line like:
#
#   Done ! The database is ready for use .
#
# you can use the database
docker run \
  --interactive \
  --name oracle \
  --publish 1521:1521 \
  --tty \
  --volume oracle:/ORCL \
  container-registry.oracle.com/database/enterprise:19.3.0.0
```

When you no longer need the database, in another terminal tab run:

```
docker stop oracle
```

The next time you need the database, start it just by running:

```
docker start --interactive oracle
```

## Setting up the Oracle Client Drivers

### Install Oracle Instant Client

1. Enable the homebrew tap for Oracle Instant Client by running `brew tap InstantClientTap/instantclient`.
1. Run each of these commands, following the displayed instructions for how to download the appropriate .zip files from Oracle’s website. After you download the files and place them in Homebrew’s cache directory, brew will take care of the rest:
    ```
    brew install instantclient-basic
    brew install instantclient-sqlplus
    brew install instantclient-sdk
    ```

### Set Up Environment Variables

1. Add to `~/.profile` (bash) or `~/.zprofile` (zsh)

```
# The Oracle adapter for ActiveRecord uses this password to connect as a
# system user, to be able to create and drop databases appropriately.
export ORACLE_SYSTEM_PASSWORD=Oradoc_db1

# This is used to specify the default language and encoding for Oracle clients
export NLS_LANG="AMERICAN_AMERICA.UTF8"
```

1. `source ~/.profile` or `source ~/.zprofile`, to load the changes you just made


### Test Your Installation

To connect to the Oracle server from within the `db` docker service, run:

```sql
sqlplus "sys/Oradoc_db1@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=ORCLCDB)))" as sysdba
```

Your output should show something like this:

```
Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL>
```

## Setting up the Database

1. Make sure you have the `activerecord-oracle_enhanced-adapter` and `ruby-oci8` gems enabled in your `Gemfile`.
1. Copy the Oracle template for `database.yml` by running `cp config/database.yml.oracle.template config/database.yml`.
1. Run `bundle exec rake db:setup`.
1. Optionally, run `bundle exec rake demo:seed` if you want to populate the database with demo data.

## Some additional notes on database setup

### Oracle error messages
Oracle error messages are often not very helpful.  For example, if you try to run `rails console` before `bundle exec rake db:setup`, you will see an error related to invalid username/password when attempting to make a query:

```bash
Loading development environment (Rails 6.0.4.4)
[1]nucore-nu(main)> User.count
OCIError: ORA-01017: invalid username/password; logon denied
from oci8.c:603:in oci8lib_260.bundle
```

The solution here is to run `rake db:setup`, nothing to do with username/password.

### Oracle image setup issues
The Oracle image can take a long time to download and initialize the first time (40+ minutes) and it also requires a lot of memory (8GB).  The logging from the oracle container is quite noisy, and error messages there usually do not indicate an actual problem.  If you encounter multiple unhelpful errors and all else fails, sometimes removing the image and starting over resolves the issue.

### Oracle database usernames
Oracle does not allow the use of "-" in database usernames.  Check your username config in `databse.yml` if you see the the following:
OCIError: ORA-00922: missing or invalid option
Couldn't create '//localhost:1521/ORCLCDB' database. Please check your configuration.

## Debugging expiring passwords

You may see an error like this when starting up the rails console:
`OCIError: ORA-28001: the password has expired`

Or when logging into sqlplus with sys user:
`ERROR: ORA-28002: the password will expire within 7 days`

Following https://blogs.oracle.com/sql/how-to-fix-ora-28002-the-password-will-expire-in-7-days-errors

... update the default user profile so that passwords don't need to be updated:
```sql
  alter profile "DEFAULT" limit
    password_life_time unlimited;

```
... then update the passwords for users you need to use for development:

`alter user <username> identified by <password>;`

```sql
  alter user sys identified by Oradoc_db1;
  alter user c##nucore_nu_development identified by password;
  alter user c##nucore_nu_test identified by password;
```

# Optional Extras

## Install Oracle SQL Developer

* Download from: `http://www.oracle.com/technetwork/developer-tools/sql-developer/overview/index.html`

* Install into `/Applications`

## Restore From Backup

1. Run `bundle exec rake db:drop db:create`. This will ensure that your database exists, and that it is empty. Without this step, the import may skip tables which already exist, and it may fail if the database does not exist.

1. Copy the `.dmp` file to `oracle/u01/app/oracle/admin/ORCL/dpdump/` (assuming you are using `oracle/` as the data directory, per above), so it is located in the server’s default data pump directory.

1. Start a bash shell in the `oracle` container:

    ```
    docker exec -it oracle bash
    ```

1. Run the following command to ensure that the file you copied is available in the `DATA_PUMP_LOCATION` configured on the server:

    ````
    ln -fsn /ORCL/u01/app/oracle/admin /u01/app/oracle/admin
    ````

  This only needs to be done once, but if you’re having trouble, rerun it.

1. Import the dump, replacing DUMPFILE with the name of your dump file, and REMAP_SCHEMA with your database’s username if necessary:

```
impdp \
  system/Oradoc_db1 \
  DIRECTORY=DATA_PUMP_DIR \
  DUMPFILE=expdp_schema_COR1PRD_201810021913.dmp \
  REMAP_SCHEMA="bc_nucore:c##nucore_open_development"
  REMAP_TABLESPACE="bc_nucore:USERS"
```
