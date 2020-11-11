# LdapAuthentication Engine

NUcore uses [Devise](https://github.com/plataformatec/devise) for authentication,
and the [`ldap_authenticatable`](https://github.com/cschiewek/devise_ldap_authenticatable)
Devise module for LDAP authentication.

When LDAP is enabled on NUcore Devise will try to authenticate users against
both the LDAP server and the local users table. Whichever works first wins.
If neither works login is denied.

## Enabling LDAP Authentication On NUcore

Start by making sure the `gem "ldap_authentication", path: "vendor/engines/ldap_authentication"`
line is present in your Gemfile.

NUcore will activate LDAP authentication if a configuration file exists.
The example config file provided with NUcore is enough to get started:

```bash
cp config/ldap.yml.template config/ldap.yml
```

The default settings are for an LDAP server running on `localhost` port 389,
which should work for the test LDAP server described below.

Change the `host:` value if you are using an external LDAP server.

## Cofigure a local LDAP server

### Configuring The LDAP dn

LDAP authenticates users with a distinguished name (`dn`), which is typically
composed of multiple LDIF attributes. One of the attributes of the `dn` will
specify the user's login. The additional attributes, for NUcore, are expected
to be consistent across all users.

LDAP users allowed to access NUcore must have a password-less record in
NUcore's users table. The record's username attribute must correspond to the
login part of the user's LDAP `dn`. The LDIF attribute identifying the login
must be the value of `ldap.yml`'s `attribute:` key.
The additional LDIF attributes that make up the remainder of the LDAP `dn` must
be the value of the `base:` key.

### Using Docker

The easiest thing to do is add an LDAP server in `docker-compose`.

1. Set the `LDAP_HOST` environment variable.  If you're running the main app outside docker, you can run `echo LDAP_HOST=localhost` or just leave `LDAP_HOST` unset (`localhost` is set as the default value in `ldap.yml`).  If you're running the main app in docker, add `LDAP_HOST=ldap` to the main app's `environment` in `docker-compose.yml`:

```yaml
  app:
    environment:
      - LDAP_HOST=ldap
```

2. Add the `ldap` and `ldap-admin` services to `docker-compose.yml`.  The `ldap-admin` service is optional:

```yaml
  ldap:
    image: osixia/openldap
    command: "--copy-service"
    ports:
      - "389:389"
    volumes:
      - "ldap-data:/var/lib/ldap"
      - "slapd-config:/etc/ldap/slapd.d"
      # Loads some default users into the database
      - "./vendor/engines/ldap_authentication/spec/fixtures:/container/service/slapd/assets/config/bootstrap/ldif/custom"

  # Optional administrative website
  ldap-admin:
    image: osixia/phpldapadmin
    ports:
      - "8081:80"
    depends_on:
      - ldap
    environment:
      - PHPLDAPADMIN_LDAP_HOSTS=ldap
      - PHPLDAPADMIN_HTTPS=false
```

3. The directories `/var/lib/ldap` (LDAP database files) and `/etc/ldap/slapd.d` (LDAP config files) are used to persist the schema and data information, and should be mapped as volumes so the files are saved outside the container.  More info on this at https://github.com/osixia/docker-openldap#data-persistence.  Add `ldap-data` and `slapd-config` to your volumes list in `docker-compose.yml`:

```yaml
volumes:
  slapd-config:
    driver: local
  ldap-data:
    driver: local
```

4. Bring up the services:
* `docker-compose up ldap`
* `docker-compose up ldap-admin`

5. Confirm the `ldap-admin` service is up and running:
* Go to: http://localhost:8081
* Login DN: cn=admin,dc=example,dc=org
* Password: admin

### Seed the directory

#### Add an organization

For testing you'll need at least one organization in the LDAP directory. If you are using
the `ldap-admin` service, the organization should already exist for you.

To create an organization:

Create a `org.ldif` file in LDAP data interchange format. Here's an example:

```
dn: dc=example,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
dc: example
o: Table XI
```

```bash
ldapadd -x -D "cn=admin,dc=example,dc=org" -w admin -f org.ldif
```

#### Add a user

You will also need at least one user in the LDAP directory. To create a user:

Create a `usr.ldif` is a file in LDAP data interchange format. Here's an example:

```
# see vendor/engines/ldap_authentication/spec/fixtures/chico.user.ldif

dn: uid=cgreen,dc=example,dc=org
uid: cgreen
cn: Chico Green
gn: Chico
sn: Green
mail: cgreen@example.org
userPassword: secret
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
```

If you are using the `ldap-admin` service, you can copy and paste an `ldif` configuration
using the "Import" feature.

```bash
ldapadd -x -D "cn=admin,dc=example,dc=org" -w admin -f usr.ldif
```

### Search the LDAP Directory

```bash
ldapsearch -x -D "cn=admin,dc=example,dc=org" -w admin -b "dc=example,dc=org" "uid=*"
```

You should see output similar to this:

```
# extended LDIF
#
# LDAPv3
# base <dc=example,dc=org> with scope subtree
# filter: uid=*
# requesting: ALL
#

# cgreen, example.org
dn: cn=cgreen,dc=example,dc=org
uid: cgreen
cn: Chico Green
givenName: Chico
sn: Green
mail: cgreen@example.org
userPassword:: bm90Z3VtcA==
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
# search result
search: 2
result: 0 Success
# numResponses: 2
# numEntries: 1
```

### Testing NUcore LDAP Authentication Integration

Create a password-less `User`:

```bash
bundle exec rails console
[1] pry(main)> User.create!(username: "cgreen", first_name: "Chico", last_name: "Green", email: "cgreen@example.org")
```

Try logging in to NUcore with username `cgreen` and password `secret`.
You should login successfully, and you should see activity in the LDAP server's
the standard output.
