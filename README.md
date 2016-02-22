SugarBash Helper
================

## About

Sugar Bash Helper may help developers with daily routines such as:

```bash
SugarBash Helper: option
========================
 0 - Quit
 1 - Backup
 2 - Mount
 3 - VPN
 4 - Git Config
 5 - xbuild
 6 - Git Mango
 7 - DB SQL
 8 - vagrantON
 9 - System Info
------------------------
Select your menu option:
```

It's easy to extend and config having all configurable parameters into YAML format on [config.yml](https://github.com/svnvcristea/sugarBash/blob/master/config.def.yml)

## Installation

### Clone sugarBash

```bash
git clone git@github.com:svnvcristea/sugarBash.git
```

### SetUp config file

```bash
cd ./sugaBash
cp ./config.def.yml ./config.yml
nano config.yml
```

Check your config.yml file and adjust accordingly

### Run the helper and explore the options

```bash
sudo bash helper.sh
```

Usage:

```bash
bash helper.sh -h
```

### Permanent Alias

Add helper.sh as alias:
```bash
echo "alias helper='bash ~/git-repo/sugarBash/helper.sh'" >> ~/.bashrc
```
then you can just type 
```bash
helper
```

## See also

* [SugarCRM CodeSniffer](https://github.com/svnvcristea/SugarCRMCodeSniffer)