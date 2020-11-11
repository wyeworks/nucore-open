# Changelog

Because we use squash and merge, you should be able to see the changes by looking
at the [commit log](https://github.com/tablexi/nucore-open/commits/master). However, we have begun keeping track of breaking changes
or optional rake tasks.

### Rename username attribute key in `ldap.yml.template` ([#2440](https://github.com/tablexi/nucore-open/pull/2440))

If you are using the [LDAP Authenitcation engine](vendor/engines/ldap_authentication/README.md) and have set a value for the `attribute` key in `ldap.yml`, you will need to rename the key to `username_attribute`.

```yaml
# Old setting
attribute: uid

# New setting
username_attribute: uid
```

### Uploaded file storage path change ([#2365](https://github.com/tablexi/nucore-open/pull/2365))

We want to move everything into `public/system`, which is the more modern standard.

In addition, with the previous default in settings.yml, files were not stored according to their
class, so objects of different types with the same IDs could share the same folder, so
we also want to add the class name to the path.

```yaml
# Old setting
paperclip:
  storage: filesystem
  url: ":rails_relative_url_root/:attachment/:id_partition/:style/:safe_filename"
  path: ":rails_root/public/:attachment/:id_partition/:style/:safe_filename"

# New setting
paperclip:
  storage: filesystem
  url: ":rails_relative_url_root/system/:class/:attachment/:id_partition/:style/:safe_filename"
  path: ":rails_root/public/system/:class/:attachment/:id_partition/:style/:safe_filename"
```

_If your old setting for `path` was something different, you'll need to change it
in `lib/tasks/paperclip-nucore.rake`_

* Take a backup of `public/files`

* Move the files to the new location

  ```
  bundle exec rake paperclip:migrate_path
  ```

* Restart the server so it points at the new location


### Welcome email refactoring/cleanup ([#2362](https://github.com/tablexi/nucore-open/pull/2362))

The locales for the new user (welcome) email have been simplified. If you have customized
this email, you will need to make some changes.

`views.notifier.new_user` no longer uses any keys with the `_html` and `_text` suffixes.
We recommend deleting one of the entries and removing the suffix from the other for each
of `intro`, `only_username`, `username_and_password`, and `outro`. The content is presented
as is for the plain-text version and parsed via Markdown for the HTML version.

For development, we've improved the previews so you can see both a netid user email
as well as an external user email. http://localhost:3000/rails/mailers/notifier

### Rename BaseMailer to ApplicationMailer ([#2362](https://github.com/tablexi/nucore-open/pull/2362))

If you have custom mailers in any of your engines, you might need to rename `< BaseMailer` to
`< ApplicationMailer`.

### Fix price group membership logs ([#2360](https://github.com/tablexi/nucore-open/pull/2360))

In order to address an issue with add/removing subclasses of PriceGroupMember, we
need to clean up old data:

```
rake cleanup:log_events:metadata
```

### [Optional] Remove Cancer Center Price Group ([#2347](https://github.com/tablexi/nucore-open/pull/2347))

Many schools do not have a cancer center, so the price group does not make sense to
include. For new implementations of NUcore, you can simply remove `price_group.name.cancer_center` from `settings.yml` when you run the seeds.

```
rake cleanup:price_groups:cancer_center
```

### [Recommended] Remove abandoned carts ([#2292](https://github.com/tablexi/nucore-open/pull/2292))

After releasing this PR, many fewer abandoned instrument-only carts should be created (see
the PR for details on why). This rake task will clean up the existing abandoned carts,
which could improve site performance for some users.

```
bundle exec rake cleanup:carts:destroy_abandoned
```
