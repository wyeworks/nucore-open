# Coding Standards/Guidelines

NUcore is an old project and has passed through many hands. There are long controller methods, complex view logic, and odd routing. It began as a Rails 2.X project and pieces of that legacy remain. Many of the things that you may consider as bad may have even been considered best practices at the time. Give the past developers some credit. Future you may have similar things to say about what you're doing right now.

Times have changed, styles and best practices have evolved, and we want to keep the codebase healthy. That means cleaning things up and refactoring as needed. We can't fix everything at once, but we can make things better one little piece at a time.

If you see a nasty or incomprehensible method, see if you can refactor it to make it more understandable. If you're trying to make a change and it's hard, [refactor to make the change easy](https://twitter.com/kentbeck/status/250733358307500032).

But do consider the value vs effort. If it's a bug fix where you have `>` instead of `>=`, it might not be worth spending four hours refactoring. But if you're working within a nasty method and you know there's constant churn on that class, it's likely worth it.

The golden rule: **when working on a piece of code, _leave it nicer than when you found it_**.

Here are some general guidelines:

## Pull Requests

**Do not commit to master!**

All changes should go through a Pull Request and be reviewed prior to merging.

## Bug fixes

If you're tracking down a bug, write a test for it. Even if you fix the bug first, undo your change, write a failing test, and then re-do your change to make it pass.

## Use locales

Views should use locales/I18n whenever possible. This facilitates easy overriding
in downstream forks. We've begun moving locales into separate files, in general
one per controller/view set. This is still a work in progress, but see `config/locales` for examples.

Fork-specific overrides should be put in `config/locales/override/en.yml`. We've
made sure this is the last file to be loaded, so it always takes precedence. Nothing
should be in that file in nucore-open except the locales that we use to verify this
behavior in specs.

We use the [text-helpers](https://github.com/ahorner/text-helpers) gem for view
and controller locales. Use the standard [Rails I18n](http://guides.rubyonrails.org/i18n.html) for model names, attributes, and error messages.

* Prefer `Model.model_name.human` and `Model.human_attribute_name` over view-specific locales
* Prefer text-helper's `text` method over `I18n.t`
* When including references to "facility" and "facilities", within a longer string,
  use text-helper's interpolation features with `facility_downcase`/`facilities_downcase`
  e.g. `text("in this !facility_downcase!"). _We haven't found a better way to do this yet_

## Rubocop

We have rubocop set up with a set of style guidelines. When you're working in a file,
try to abide the guidelines (e.g. prefer double over single quotes, use 1.9-style
hash syntax, etc). Please run `rubocop` on the files you're touching, and preferably only
on the files you're touching.

It's difficult to see a salient change amidst a lot of stylistic updates, so if you
run rubocop or do another large stylistic update, give it a separate commit, or even
its own PR if the changes are significant enough.

Views are not Rubocopped, nor are Rails-specific cops inside of engines, so try to
follow the same style guidelines.

* Use Ruby 1.9 hash syntax

  ```ruby
  :key => value # Bad
  key: value # Good
  ```

* Prefer double-quotes to single-quotes
* Prefer `before_action` to `before_filter`
* Prefer `find_by(key: value)` over dynamic finders (`find_by_key(value)`)

## Fork-specific changes

Some features such as authentication or financial system integration may be specific to
a particular instance of NUcore. These kinds of features should be developed within their
respective downstream forks. When developing these kinds of features, it is important to
avoid making changes to application code (primarily `/app` and `/lib`) that also exists in
the open-source fork. Otherwise, there is a high likelyhood of merge conflict if anything
changes upstream.

The best method is to isolate your feature inside of an engine in `vendor/engines`. When
necessary, create a hook point where you need it within the open-source branch and hook
into that with your engine. Try to avoid overriding entire views (as happens in
the `c2po` engine). Then a change to the default view might need to happen in
multiple places. See the following section for more information.

* A factory configured in settings (e.g. `ValidatorFactory`, `StatementPdfFactory`
* Adding a module onto an existing class in the engine initializer (see `vendor/engines/c2po/lib/c2po.rb`)
* Other things we haven't thought of

## Extending views within engines

When necessary, you can add to a view from your engine with minimal change to the
main application's view.

`render_view_hook("useful_identifier", local_variables)`

`"useful_identifier"` should be relevant to where it exists in the view. E.g.
`after_end_of_form`.

To insert a partial into this hook, within your engine's `to_prepare` block, add

```ruby
config.to_prepare do
  ViewHook.add_hook("partial_name", "useful_identifier", "your_engine/partial")
end
```

`partial_name` - The name of the partial where `render_view_hook` lives. It should use dots, and will be the same as the locale scope for the view. E.g. if you call `render_view_hook` in `reservations/_account_field.html.haml`, the `partial_name` will be `reservations.account_field`

`your_engine/partial` - The name of the partial you wish to include, located within your engine.

[`vendor/engines/projects/lib/projects/engine.rb`](vendor/engines/projects/lib/projects/engine.rb) has plenty of examples, as well
as examples of other ways to hook into the app from an engine.

## Gemfiles

There will necessarily be differences between the `Gemfile`s of different instances (the
included engines, database, etc.). Do your best to keep the common gems in Gemfiles are in
the same order. This will help prevent merge conflicts in `Gemfile`. Unfortunately, merge
conflicts within `Gemfile.lock` are likely inevitable.

If you are building an engine that depends on an additional gem, add that dependency to the
engine's `gemspec`, not app's `Gemfile`.

_We should consider `optional` groups in Bundler 1.10 to see if this helps_

## Commits

Good commit messages vastly improve the history of the project. Tools like `git log`,
`git blame`, and `git bisect` are much easier to use when each commit is a discrete
piece of work. Each commit to master should result in a green build.

When merging Pull Requests, we prefer to use Github's "Squash and Merge" green button.
This allows the history of `master` to be one commit per feature or bug fix. It
also keeps commits from long-running PRs to be included in the history in chronological
order of when they were merged, not when they were written.

Use [Chris Beam's guidelines](https://chris.beams.io/posts/git-commit/) as a template
for your commits.

Prefix your pull requests with the ticket number. `[#12345] Fix critical issue`.
This is an open source project, so many people will not have access to the discussion
of the ticket, so include an explanation of the feature or bug fix in the pull
request body.

## Other

### Put application code where it belongs
There is quite a bit of code inside of `/lib` that is actually application code. Many of the
classes/modules are actually service objects or model concerns. Move them to the appropriate
place inside of `/app`.

We have an `app/support` directory that probably would be more at home in `app/services` or `app/models/concerns`. Move them to where they belong. This has led to an odd `spec` folder structure where `spec/support` is for testing support, and `spec/app_support` holds the tests for `app/support`.

Don't worry too much about moving code you're not actively working with. But when you do work on
something that seems to be in the wrong place, please fix it!

### Don't use DCI
There are a few places where we are using [DCI](http://www.sitepoint.com/dci-the-evolution-of-the-object-oriented-paradigm) such as `PriceDisplayment`. Do not use this technique going forward. Prefer decorators/presenters. Consider [`SimpleDelegator`](http://ruby-doc.org/stdlib/libdoc/delegate/rdoc/SimpleDelegator.html) or [`DelegateClass`](http://ruby-doc.org/stdlib/libdoc/delegate/rdoc/Object.html); we have chosen not to use something
more magical like Draper.

### Documentation
If a class is not immediately obvious what its purpose is, add comments to the top of the
class explaining its purpose and its use.

### Skinny Models, Controllers, and Views
You'll see lots of long controller methods or complex logic in the views. Don't contribute to the problem. If you need to touch one of these, start by refactoring out a service object or presenter. Additionally, try to avoid adding additional business logic onto the models. `OrderDetail` is already [large enough](https://en.wikipedia.org/wiki/God_object)!

### Roles
Prefer `Ability` checks (`can? :read, @order_detail)` over Role checks in views and controllers (e.g. `User#manager_of?(facility)`).

## Once again, leave things better than you found them.

And remember, break any of these rules sooner than do anything outright barbarous.
