Sugar Bash Helper
=================

# 1) About

It's easy to extend and config having all configurable parameters into YAML format on config.yml
This Sugar bash script helper will support daily routines as:
 * Backup your files
 * Mount shared folders
 * VPN connect & disconnect
 * SugarCRM create build (based on xbuild)
 * Git config globals
 * Import SQL dump
 * System Info


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

# 3) See also

* [SugarCRM CodeSniffer](https://github.com/svnvcristea/SugarCRMCodeSniffer)