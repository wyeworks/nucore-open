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

```
# Run everything against the VM
ansible-playbook -i local.yml nucore_rails_app.yml
```
