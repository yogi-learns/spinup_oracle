# spinup_oracle
A vagrant box that provisions Oracle Database **(19c)** automatically, using Vagrant, an **Oracle Linux 8** box and a shell script.

## Prerequisites
1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://vagrantup.com/)

## Getting started
1. Clone this repository `git clone https://github.com/yogiboy/spinup_oracle.git`
2. Download the installation zip files from OTN into this folder - first time only:
   * Oracle 19.3.0 base binaries - `LINUX.X64_193000_db_home.zip`
   * Oracle 19.7 RU - `p30869156_190000_Linux-x86-64.zip`
   * Oracle Opatch latest - `p6880880_190000_Linux-x86-64.zip`
3. Run `vagrant up`
   1. The first time you run this it will provision everything and may take a while. Ensure you have (a good) internet connection as the scripts will update the virtual box to the latest via `dnf`.
   2. The Vagrant file allows for customization, if desired (see [Customization](#customization))
4. Connect to host
   1. via putty (localhost) using `common_private_key` and vagrant user.
   2. via vagrant ssh
5. Connect to the database.
6. You can shut down the box via the usual `vagrant halt` and the start it up again via `vagrant up`.

## Connecting to Oracle
* Hostname: `localhost`
* Port: `1521`
* SID: `ORCLCDB`
* PDB: `ORCLPDB1`
* OEM port: `5500`

## Resetting password
You can reset the password of the Oracle database accounts (SYS, SYSTEM and PDBADMIN only) by executing `/home/oracle/setPassword.sh <Your new password>`.

## Other info

* If you need to, you can connect to the machine via `vagrant ssh`.
* You can `sudo su - oracle` to switch to the oracle user.
* The Oracle installation path is `/opt/oracle/` by default.
* On the guest OS, the directory `/vagrant` is a shared folder and maps to wherever you have this file checked out.

### Customization
You can customize your Oracle environment by amending the environment variables in the `Vagrantfile` file.
The following can be customized:
* `ORACLE_BASE`: `/opt/oracle/`
* `ORACLE_HOME`: `/opt/oracle/product/19c/dbhome_1`
* `ORACLE_SID`: `ORCLCDB`
* `ORACLE_PDB`: `ORCLPDB1`
* `ORACLE_CHARACTERSET`: `AL32UTF8`
* `ORACLE_EDITION`: `EE` | `SE2`
* `LISTENER_PORT`: `1521` (edit the `LISTENER_PORT = 1521` line to customize)
* `EM_EXPRESS_PORT`: `5500` (edit the `EM_EXPRESS_PORT = 5500` line to customize)
* `ORACLE_PWD`: `K2ypton55`
* `BASE_ZIP`: `LINUX.X64_193000_db_home.zip`
* `PATCH_LOC`: `/opt/oracle/release-update`
* `PATCH_NUMBER`: `30869156`
* `PATCH_ZIP`: `p30869156_190000_Linux-x86-64.zip`
* `OPATCH_ZIP`: `p6880880_190000_Linux-x86-64.zip`

*All code in this repo, is inspired from what Oracle maintains* 
