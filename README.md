# deb.mkg20001.io

A PPA offering various pieces of software downloaded from their orignal vendors for automatic updating

Currently offering:
- [duniter](https://duniter.org)
- [OpenBazaar](https://openbazaar.org)
- [Vagrant](https://vagrantup.com)
- [Packer](https://packer.io)
- [mitmproxy](https://mitmproxy.org)
- [Siderus Orion](https://siderus.io)
- [Google Chrome](https://google.com/chrome) _(will add it's own PPA after installing)_
- [Keybase](https://keybase.io)
- [Syncthing](https://syncthing.net)
- _and many more..._

# Installation

```
sudo apt-get install -y dpkg-dev distro-info jq gnupg2
cd $HOME
git clone https://github.com/mkg20001/ppa-script.git
git clone https://github.com/mkg20001/deb.mkg20001.io.git PPA
```

(You also need ipfs-dnslink-update installed & configured)

Now add `@daily bash $HOME/PPA/config/cron.sh` to your crontab

