Sugar Bash Helper
=================

# 1) About

It's easy to extend and config having all configurable parameters into YAML format on config.yml
This Sugar Bash helper will support daily routines as:
 * Backup your files
 * Mount shared folders
 * VPN
    * kill
    * connect
 * Git Config:
    * globals email and username
 * xBuild - SugarCRM create build
 * Git Mango:
    * clone
    * setup repo
    * post checkout branch
    * patch based on instance staged files
 * Import SQL dump
 * System Info
    * OS
    * Disk
    * Actual folder size
    * Actual folder write benchmark
    * Top 10 sub-folders size


# 2) Installation

### Clone sugarBash


  ```bash
 git clone git@github.com:svnvcristea/sugarBash.git
  ```

### SetUp config file

Copy config.def.yml to config.yml

  ```bash
cd ./sugaBash
cp ./config.def.yml ./config.yml

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

# 3) See also

* [SugarCRM CodeSniffer](https://github.com/svnvcristea/SugarCRMCodeSniffer)