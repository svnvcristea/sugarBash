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
     1 - SugarEPS
     2 - Stack php54
     3 - Stack oracle12c
 3 - VPN
     1 - VPN Connect
     2 - VPN Kill
     3 - VPN status
 4 - Git
     1 - Config email and username
     2 - GitHub Clone
     3 - SugarCRM Build init
 5 - xbuild
     0 - sugar-qa
     1 - sugar
     2 - sugar2
 6 - Git Mango
     1 - clone
     2 - post checkout
     3 - patch
 7 - DB MySQL
     1 - show users
     2 - user privileges
     3 - set root
     4 - DB size
     5 - import dump
 8 - vagrantON
     1 - clone
     2 - status
     3 - up
     4 - ssh
     5 - resume
     6 - suspend
     7 - destroy
 9 - System Info
     1 - Full info
     2 - OS
     3 - disk
     4 - Actual folder size
     5 - Actual folder write benchmark
     6 - Top 10 sub-folders size
10 - SugarDevEnv
     1 - PHPUnit
         1 - install
         2 - PHPUnit Sugar Customization Test Suite
------------------------
Select your menu option:
```

It's easy to extend and config having all configurable parameters into YAML format on config/*.yml as [config.yml](https://github.com/svnvcristea/sugarBash/blob/master/config.def.yml)

## Installation

### Clone sugarBash

```bash
git clone git@github.com:svnvcristea/sugarBash.git
```

### SetUp config file

```bash
cd ./sugaBash
nano config/_private.yml
```

Check your ```config/_private.yml``` and overwrite ```config/config.yml``` values accordingly with your environment

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
echo "alias helper='bash ~/sugarBash/helper.sh'" >> ~/.bashrc
echo "alias von='bash ~/sugarBash/helper.sh von'" >> ~/.bashrc
```
then you can just type 
```bash
helper
```

## See also

* [SugarCRM CodeSniffer](https://github.com/svnvcristea/SugarCRMCodeSniffer)