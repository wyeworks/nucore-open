# Configuring Via Ansible

## Assumptions

This code assumes that:

1. *You have a UMass NetID.* Contact someone on the current NUcore team to get this.
1. *You have SSH and sudo access to the Corum servers.* Contact someone on the current NUcore team to get this.
1. *You have Ansible installed on your computer.* If needed, follow the setup steps below to do this.
1. *You are connected to the UMass IT VPN.* Corum servers only allow SSH access to users connecting via the `vpn-it.umass.edu` host.
1. *Your SSH client is set up to connect to Corum servers using the correct username.* This will most likely be your NetID.  If your ssh client is setup to connect with a different username, you can add an entry to `~/.ssh/config` like this:

    ```
    Host *.umass.edu
    User <YOUR-USERNAME-ON-THE-UMASS-SERVERS-HERE>
    ```
1. *You are running commands from the `ansible` directory.*

## Setup

Install dependencies.

See https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
OR
`brew install ansible`

then

```
ansible-galaxy install -r requirements.yml
```

## Deploying Changes

Generally, any infrastructure changes you make should first be tested on staging, and only after being verified, should they be made on production. A typical workflow for this might be:

1. Make your changes on a branch, and open a Pull Request. As you are doing this, you can apply your changes to staging to test your work, but be careful about communicating with others about potential breaking changes.
1. After your Pull Request is approved, apply it to staging:

    ```
    ansible-playbook -i staging site.yml
    ```
1. After you have successfully applied your Pull Request to staging, and you are convinced that it works as intended, apply it to production:

    ```
    ansible-playbook -i production site.yml
    ```
1. After you have successfully applied your Pull Request to production, and you are convinced that it works as intended, merge your Pull Request to `master`.

This workflow has the benefit of being able to quickly undo your changes if something unexpected happens: you can always check out `master` and run `ansible-playbook` there to revert to the last-known-to-work state of the world.

### Usage notes

1. You can use the following flags to perform a dry run and check changes:
    * `--check` - don't make any changes; instead, try to predict some of the changes that may occur
    * `--diff` - when changing (small) files and templates, show the differences in those files; works great with –check
1. You may need to specify your netid as the username  with `-u` in order to access ssh:
    ```
    ansible-playbook -i <ENVIRONMENT> --check --diff site.yml -u <NETID>
    ```
1. To run only particular roles from the playbook, specify one or more of the tags defined in `site.yml`:
    ```
    ansible-playbook -i <ENVIRONMENT> site.yml --tags "nginx"
    ```
1. You may need to specify `no_proxy='*'` to work around a python bug on Mac OS:
    ```
    `no_proxy='*' ansible-playbook -i <ENVIRONMENT> --check --diff site.yml -u <NETID>
    ```
    For more info see https://github.com/ansible/ansible/issues/32554
1. During the task `[rvm.ruby : Import GPG keys from keyservers]`, you may see errors like:
    ```
    "gpgkeys: HTTP fetch error 56: Recv failure: Connection reset by peer"
    ```
    The rvm.ruby module has a fallback for this:
    ```
    [rvm.ruby : Import GPG keys from rvm.io, if keyservers failed]
    ```
    These errors can be safely ignored.

### Environments

* `development` (this is UMass's development environment, not to be confused with Rails's env)
* `staging` (what UMass calls "test")
* `production`

## Development/Testing

*NOTE - the following has not been tested recently and may not work as expected.*

For testing:
* set up a VM
* run the ansible playbook against it
* confirm the results are what you expect

You can use [Vagrant](https://www.vagrantup.com/) to set up a VM for developing your Ansible playbook.

* Download [VirtualBox](https://www.virtualbox.org/)
* Install Vagrant: `brew install vagrant`
* Bring up the VM and provision it: `vagrant up`
* Make your changes
* `vagrant provision` will re-run the playbook
* You can start over with a fresh VM with `vagrant destroy`

SSH into the VM: `ssh -p 2222 localhost`

You might want to add this to your `~/.ssh/config` file to avoid dealing with host
changed errors as you spin up and down VMs.

```
Host localhost
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
```

You'll need to set up your database.yml, secrets.yml, and eye.yml.erb, but you
can now `cap ansible deploy` to try actually deploying the app to the VM.

## SSL Certificates

```
sudo mkdir /etc/nginx/ssl
sudo mv corum.umass.edu.* /etc/nginx/ssl
sudo chmod 600 /etc/nginx/ssl/corum.umass.edu.*
sudo chown root /etc/nginx/ssl/corum.umass.edu.*
sudo chgrp root /etc/nginx/ssl/corum.umass.edu.*
```
