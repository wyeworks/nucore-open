# SamlAuthentication Engine

NUcore uses [Devise](https://github.com/plataformatec/devise) for authentication,
and uses the [`saml_authenticatable`](https://github.com/apokalipto/devise_saml_authenticatable)
module for SAML integration.

## General steps for setting up

1. Get the URL of the IdP's metadata
1. Enable this gem, generate a certificate, and update the settings as described in "Enabling SAML Authentication"
1. Deploy the application
1. Import the app's (SP) metadata into the IdP (at `https://yourhost.edu/users/saml/auth`)
1. Debug

## Enabling SAML Authentication

Add the following line to your `Gemfile` if it is not already present:

```ruby
gem "saml_authentication", path: "vendor/engines/saml_authentication"`
```

In `config/settings.yml`, uncomment the `saml` section and adjust the settings
as necessary to connect with your Identity Provider (IdP).

```yaml
saml:
  login_enabled: true
  idp_metadata: "https://websso.example.com/idp/metadata"
  certificate_file: path/to/file.p12
  driver:
    name_identifier_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
  attribute_map:
    "PersonImmutableID": "username"
    "User.email": "email"
    "User.FirstName": "first_name"
    "User.LastName": "last_name"
```

* During the initial phase of development, you might want to set `login_enabled` to false so the metadata is exposed, but the big "Single Sign On" button is not yet available.
* `idp_metadata`: The URL for your IdP's metadata. This should be provided to you by the IdP. This URL is fetched at application startup.
* `certificate_file` (Optional, but highly recommended): A `.p12` certificate file for signing your requests.
  _Do not check this in to version control_. See below for instructions on creating
  a certificate.
* `attribute_map`: A mapping from the IdP's attributes to the NUcore's `users` table
  columns. `username` and `email` are absolutely required while entries for `first_name`
  and `last_name` are recommended.
* `driver`: An optional mapping of settings to pass to the underlying ruby-saml
  gem. See *What Needs to be Configured* at https://developers.onelogin.com/saml/ruby
  for a list of valid keys. This useful if the default inferred SAML settings
  need to be overrided.

## Handling Users

When a user logs in one of three things will happen (in this order):

1. If the username field (as specified in `attribute_map`) matches an existing
   NUcore `User`, they will be logged in. Other attributes coming from the SAML
   exchange (`email`, `first_name`, `last_name`) will be updated.
2. If the SAML user's email address matches an existing `User`'s email address,
   the user's `username` will be updated as will other attributes. The user's
   password will be cleared, and they will no longer be able to log in via
   username/password. They will always need to log in via SSO in the future.
3. If the user's username or email does not match an existing a user, a new `User`
   will be created (and `create_user` is turned on). They will not be able to do much at this point because they
   will have no payment sources. A facility staff/director/administrator will need
   to set that up for them.

## Testing and Development

If you do not have full access to your IdP's configuration, [OneLogin](https://www.onelogin.com/)
is a good solution for a free IdP. Use one of their "SAML Test Connector (IdP)"
applications.

OneLogin application configuration:

`settings.yml`'s `idp_metadata` will be something like `https://app.onelogin.com/saml/metadata/123456`

* **Audience:** `http://localhost:3000/users/saml/metadata`
* **Recipient:** `http://localhost:3000/users/saml/auth`
* **ACS (Consumer) URL Validator:** `http:\/\/localhost:3000\/users\/saml\/auth`
* **ACS (Consumer) URL:** `http://localhost:3000/users/saml/auth`
* **Single Logout URL:** `http://localhost:3000/users/saml/idp_sign_out`

## Notes on `saml_authenticatable`

There are currently several overrides against the base gem in order to work with NUcore.

[saml_authentication/model.rb](lib/saml_authentication/model.rb) - Allows us to use
our settings file for the attribute map (SAML keys vs User attribute/columns)

[saml_authentication/routes.rb](lib/saml_authentication/routes.rb) - The gem's
routes conflict with the standard Devise database_authenticatable routes.

[controllers/saml_authentication/sessions_controller.rb](app/controllers/saml_authentication/sessions_controller.rb) - Store
the "winning strategy" so we can chose a logout path based on how you logged in, and handle IdP-initiated single logout.

## Single Logout

There are two types of SLO: SP-initiated and IdP-initiated. SP is when you click the "Logout" button
on NUcore. IdP is when you sign out from the identity provider.

As part of SLO, the user is logged out of NUcore, the IdP, and any other applications
that authenticated with the IdP as part of the same IdP session.

Example:
* User authenticates into webmail with username/password through the IdP
* On NUcore, when the user clicks the single sign on button to log in, they do not
  need to re-enter their username/password because they are already logged in to the IdP. They
  will be automatically logged in.
* If the user clicks the "Logout" button on NUcore, they will also be logged out of their
  webmail. If they try to log in to NUcore again, they will be prompted for the IdP's
  username and password.

### NUcore/SP-initiated Logout

1. User clicks "Logout" on NUcore
2. User's session is invalidated by Devise
3. In SamlAuthentication::SessionsController, the `after_sign_out_path` generates a logout request
   and redirects the user's browser to the IdP with the request as a Base64-encoded/encrypted query
   parameter.
4. IdP logs user out, and does an IdP-initiated logout for any other applications that were
   authenticated as part of the same IdP session.
5. Once complete, IdP redirects the user's browser to `SamlAuthentication#idp_sign_out` with a `SAMLResponse`
   param.
6. We redirect the user to NUcore's homepage (or facility's homepage)

### IdP-initiated Signout

1. User clicks "Logout" on the IdP's site
2. IdP generates a `SAMLRequest` parameter and redirects the user's browser to
   `SamlAuthentication::SessionsController#idp_sign_out` with the parameter as part
   of the query string.
3. NUcore invalidate the user's session
4. NUcore generates an SLO logout response (saying we successfully logged the user out),
   and redirects the user's browser back to the IdP.
5. The IdP logs the user out of any other applications that were authenticated as part of
   the same IdP session.
6. User is redirected to somewhere on the IdP's site (e.g. the login page)

### Generating a certificate

On a Linux-based system, generate a self-signed certificate.

```
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -nodes
# Enter country name, common name, etc.
openssl pkcs12 -inkey key.pem -in cert.pem -export -out saml-certificate.p12
# Leave passphrase blank
chmod 640 saml-certificate.p12
rm *.pem
```
