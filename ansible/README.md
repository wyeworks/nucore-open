# Configuring Via Ansible

_Note: all commands in this document assume you are in the `ansible` directory_

## Setup

Install dependencies.

```
ansible-galaxy install -r requirements.yml
```

## Deployment

```
ansible-playbook -i <ENVIRONMENT> site.yml
```

Environments:
* `development` (this is UMass's development environment, not to be confused with Rails's env)
* `staging` (what UMass calls "test")
* `production`

## Development

You can use [Vagrant](https://www.vagrantup.com/) for developing your Ansible playbook.

* Download [VirtualBox](https://www.virtualbox.org/)
* Install Vagrant: `brew cask install vagrant`
* Bring up the VM and provision it: `vagrant up`
* Make your changes
* `vagrant provision` will re-run the playbook
* You can start over with a fresh VM with `vagrant destroy`

SSH: `ssh -p 2222 localhost`

You might want to add this to your `~/.ssh/config` file to avoid dealing with host
changed errors as you spin up and down VMs.

```
Host localhost
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
```
