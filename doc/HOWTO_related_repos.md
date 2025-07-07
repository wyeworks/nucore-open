# Branches and Related Repositories

NUcore is usually deployed from a school-specific repo containing customized branding
and functionality. There are situations where you may need to bring changes
from the `nucore-open` repo into a school-specific repo, or the other way around.
In order to move commits between the repos you'll need to set up remote
repositories on each side.

## Bringing changes from `nucore-open` into a school-specific repo

You can either bring over all the new changes with a `latest_from_open_MMDDYYYY` branch,
or just a few commits with a cherry-picked branch.

### General deployment process

1. Start in the directory of the school repo (for example, `nucore-nu`)
1. Open a new branch (for more details see the sections on creating a [latest_from_open](#creating-a-latest_from_open_mmddyyyy-branch) or [cherry-picked](#creating-a-branch-with-cherry-picked-commits) branch below)
1. Merge the PR (not squash) once it has been approved and CI is green [(see below)](#squash-vs-merge)
1. For a production release, create a Github release [(see below)](#creating-a-github-release)
1. Deploy the new code using Github Actions [(see below)](#deploy)
1. Perform any release/deployment related tasks (e.g. add new env variables, run one-off rake task, etc.)
1. Check the site in a browser and confirm new functionality is there

## Creating a branch with cherry picked commits
You can cherry-pick commits from `upstream`/`nucore-open` to create more focused PRs.
This can be useful for features that have more risk or dependencies and should be deployed
and tested separately (ruby upgrades, etc).  In the school repo (for example, `nucore-nu`):
```
git co -b upgrade_ruby_2_6_6
git fetch upstream
git cherry-pick XXXXX
```

## Creating a `latest_from_open_MMDDYYYY` branch

To keep each school in sync with `nucore-open`, the latest changes from `nucore-open` are merged in on a regular basis.

_While in your school-specific repo's directory_

1. Add a new remote called `upstream` that points to the `nucore-open` repo
(you should only need to do this once): `git remote add upstream git@github.com:tablexi/nucore-open.git`
1. Create a new branch with the name `latest_from_open_MMDDYYYY` (reflecting the current date).
1. Whenever you want to bring the latest changes from open/master into your branch: `git fetch upstream` and then `git merge upstream/master`
1. Run [`bin/merge_describer`](bin/merge_describer) which generates a helpful description you can copy/paste into your PR.  It contains the commit messages and links to the merged branches since the last merge to master.  You can also pass in other branch names or tags to target for the comparison.
1. Push up your new branch to GitHub, and paste the output from `bin/merge_describer` into the PR description.  For clarity it's best to sort commits into 3 groups: features, fixes, and tech tasks.

### Notes

You can use the [`bin/latest_from_open`](bin/latest_from_open) script to create a new `latest_from_open_MMDDYYYY` branch instead of using the steps above.  Add the `upstream` remote, then run `bin/latest_from_open 04012021`.

When merging in changes from the open source repo, differences in `scehma.rb` and `Gemfile.lock` tend to be the trickiest to resolve.  Run `bundle` and `rails db:migrate` locally to ensure any conflicts have been resolved as expected.

Before merging “latest from open” PRs, make sure that the related PR against nucore-open has deployed successfully.

## Squash vs Merge

*The `bin/merge_describer` script only describes commits which include the parenthesized branch number.*

On github, squash commits include a parenthesized branch number like `(#45)` in the commit title by default, except when the PR only includes 1 commit. Merge commits do not include the parenthesized branch number in the title. So...

* Use **Squash** for feature PRs, and copy the PR description into the squash merge message.  Make sure the parenthesized branch number is in the commit title so the squash commit will get described later on in the GitHub release and release notes.
* Use **Merge** commits for `latest_from_open_MMDDYYYY` branch PRs.  Make sure that the related PR against nucore-open has deployed successfully before merging.

## PR Titles

For feature PRs, the PR title will become the squash commit message. These appear later in the `bin/merge_describer` and `bin/release_describer` output, which is used in the`latest_from_open_MMDDYYYY` PR description, github release, and release notes. Try to write feature PR titles that focus on user outcomes rather than technical details - "Fix ability to download CSV" is preferred over "Resolve issues with JSON parsing".

PR Titles that include “Shared Dev” or “Tech Task”, or start with “Security:” or “Fix:” will be automatically sorted by `bin/release_describer`.

## Creating a GitHub release

1. Check out the commit you want to release and tag it: `git tag v2021-02-18`
1. Use `bin/merge_describer v2021-01-28` to list all commits since the previous release tag
1. Organize the output into features, fixes and tech tasks
1. Create a new release in Github using this list of commits for the description
1. Specify the new tag (`v2021-02-18`) for the release tag version, target, and release title

# Bringing changes from your school-specific repo into `nucore-open`

This doesn't come up as often, but sometimes you may need to bring a view hook or feature flag into open in order to support a school-specific customization.
The best way to bring the changes from a school-specific repo is by checking out a branch from `nucore-open` and cherry-picking the desired school-specific commits. For this reason, it's best to develop on `nucore-open` to start with, or to squash the commits in your branch so you only need to bring one commit.

For example, to bring changes from `nucore-nu` into `nucore-open`:

_While in the `nucore-open` directory_

```
git remote add nu git@github.com:tablexi/nucore-nu.git
git fetch nu
git cherry-pick XXXXX
```

# Deploy

Deploy process will vary depending on the hosting setup.
Github Actions is used to trigger deploys for cloud-hosting setups (ECS and Azure).

## Github Actions deploy steps

### To staging:

Merging to `master` will trigger a stage deployment.

### To production:

Create a Github Release with a tag starting with `v` to trigger a production deployment.
