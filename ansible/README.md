# Configuring Via Ansible

## Setup

Install dependencies.

```
ansible-galaxy install -r requirements.yml
```

## Development

* Download [Fedora](https://getfedora.org/en/server/download/)
* Download [VirtualBox](https://www.virtualbox.org/)
* Install Fedora as a new VM within VirtualBox
* During installation, create a user for yourself as an administrator (the rest of these instructions will assume the name `developer` for ease of copy/paste, but feel free to change it)
* Turn on port forwarding in VB (Device > Network Settings > Advance > Port Forwarding)
  * Forward Host port 2222 to Guest port 22 (this will allow SSH access)
  * Forward Host port 8888 to Guest port 80 (this will allow HTTP access)

You'll need to manually copy your public key for root access the very first time. Once
you run the playbooks all of the keys under `authorized_keys` will have access.

```
scp -P 2222 public_keys/<yourname>.pub developer@localhost:/home/developer/developer.pub
ssh -p 2222 developer@localhost # Uses username/password login
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat developer.pub > ~/.ssh/authorized_keys
```

You also need to allow password-less sudo. `sudo vi /etc/sudoers`. Find and uncomment this line: `# %wheel        ALL=(ALL)       NOPASSWD: ALL`


```
# Run everything against the VM
ansible-playbook -i local site.yml
```

TODO:

- [ ] Add `export RAILS_ENV=stage` to `.bashrc` programatically
