# Configuring Via Ansible

## Setup

We need this library: `ansible-galaxy install rvm.ruby`

## Development

* Download [Fedora](https://getfedora.org/en/server/download/)
* Download [VirtualBox](https://www.virtualbox.org/)
* Install Fedora as a new VM within VirtualBox
* During the installer, set a root password (can be whatever you want) and a `nucore` user
* Turn on port forwarding in VB (Device > Network Settings > Advance > Port Forwarding)
  * Forward Host port 2222 to Guest port 22 (this will allow SSH access)
  * Forward Host port 8888 to Guest port 80 (this will allow HTTP access)

You'll need to manually copy your public key for root access the very first time. Once
you run the playbooks all of the keys under `authorized_keys` will have access.

```
scp -P 2222 public_keys/<yourname>.pub root@localhost:/root/<yourname>.pub
ssh -p 2222 root@localhost # Uses username/password login
mkdir -p ~/.ssh
cat <yourname>.pub > ~/.ssh/authorized_keys
```

```
# Run everything against the VM
ansible-playbook -i local.yml nucore_rails_app.yml
```
