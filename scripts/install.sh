#!/bin/bash
set -e

echo 'INSTALLER: Started up'

# get up to date
dnf upgrade -y

echo 'INSTALLER: System updated'

# fix locale warning
dnf reinstall -y glibc-common
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

echo 'INSTALLER: Locale set'

# set system time zone
sudo timedatectl set-timezone Asia/Kolkata
echo "INSTALLER: System time zone set to Asia/Kolkata"

# Install Oracle Database prereq and openssl packages
dnf install -y oracle-database-preinstall-19c openssl

echo 'INSTALLER: Oracle preinstall and openssl complete'

if [[ -f $ORACLE_BASE/oradata/${ORACLE_SID}/control01.ctl ]]; then
  echo 'Removing previously installed database and ORACLE DB binaries'
  cp /vagrant/deinstall_responsefile.rsp /tmp/deinstall_responsefile.rsp
  sed -i -e "s|ORACLE_SID|${ORACLE_SID}|g" /tmp/deinstall_responsefile.rsp
  $ORACLE_HOME/deinstall/deinstall -silent -paramfile /tmp/deinstall_responsefile.rsp
fi

# create directories
echo 'Cleanup old stuff ...'
rm -rf $ORACLE_HOME /u01/app /opt/oracle /opt/ORCLfmap /etc/oraInst.loc /etc/oratab
mkdir -p $ORACLE_HOME
mkdir -p /u01/app
ln -s $ORACLE_BASE /u01/app/oracle
mkdir -p /opt/oracle/release-update

echo 'INSTALLER: Oracle directories created'
echo

# set environment variables
echo "export ORACLE_BASE=$ORACLE_BASE" >> /home/oracle/.bashrc
echo "export ORACLE_HOME=$ORACLE_HOME" >> /home/oracle/.bashrc
echo "export ORACLE_SID=$ORACLE_SID" >> /home/oracle/.bashrc
# I dont like this. But lets use this until oracle fixes it.
echo "export CV_ASSUME_DISTID=${CV_ASSUME_DISTID}" >> /home/oracle/.bashrc
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc
echo 'INSTALLER: Environment variables set'

# Install Oracle
echo 'Unzipping base binaries ...'
unzip -q -o /vagrant/${BASE_ZIP} -d $ORACLE_HOME/
cp /vagrant/ora-response/db_install.rsp.tmpl /vagrant/ora-response/db_install.rsp
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /vagrant/ora-response/db_install.rsp
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /vagrant/ora-response/db_install.rsp
sed -i -e "s|###ORACLE_EDITION###|$ORACLE_EDITION|g" /vagrant/ora-response/db_install.rsp
chown oracle:oinstall -R $ORACLE_BASE

# Get latest OPatch

rm -rf $ORACLE_HOME/OPatch
printf 'Unzipping OPatch ...\r\n'
su -l oracle -c "yes | unzip -q -o /vagrant/${OPATCH_ZIP} -d $ORACLE_HOME/"

# Install 19.7.0.0 RU
printf 'Unzipping latest RU ...\r\n'
su -l oracle -c "yes | unzip -q -o /vagrant/${PATCH_ZIP} -d ${PATCH_LOC}/"

printf 'Installing Oracle Home ...\r\n'
echo "cd ${PATCH_LOC}/${PATCH_NUMBER}" >> /home/oracle/.bashrc
su -l oracle -c "yes | $ORACLE_HOME/runInstaller -silent -ignorePrereqFailure -waitforcompletion -responseFile /vagrant/ora-response/db_install.rsp"

printf '  Installing software only ...\r\n'
#$ORACLE_BASE/oraInventory/orainstRoot.sh
$ORACLE_BASE/oraInventory/orainstRoot.sh
$ORACLE_HOME/root.sh

rm /vagrant/ora-response/db_install.rsp

printf 'Patching Oracle HOME with latest RU\r\n'
su -l oracle -c "yes | $ORACLE_HOME/OPatch/opatch apply -silent"
su -l oracle -c "yes | sed -e \"/${PATCH_NUMBER}/d\" -i /home/oracle/.bashrc"

source /home/oracle/.bash_profile

# Cleanup space
rm -rf ${PATCH_LOC}/${PATCH_NUMBER}

echo '  INSTALLER: Oracle software installed'

# create sqlnet.ora, listener.ora and tnsnames.ora
su -l oracle -c "mkdir -p $ORACLE_HOME/network/admin"
su -l oracle -c "echo 'NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)' > $ORACLE_HOME/network/admin/sqlnet.ora"
# Bug with datapatch - temporarily add - https://mikedietrichde.com/2015/09/29/no-os-authentication-datapatch-will-fail-in-every-upgrade/
su -l oracle -c "echo 'SQLNET.AUTHENTICATION_SERVICES=(BEQ)' >> $ORACLE_HOME/network/admin/sqlnet.ora"

# Listener.ora
printf 'Creating TNS stuff ...\r\n'
su -l oracle -c "echo 'LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT)) 
  ) 
) 

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
' > $ORACLE_HOME/network/admin/listener.ora"

su -l oracle -c "echo '$ORACLE_SID=localhost:$LISTENER_PORT/$ORACLE_SID' > $ORACLE_HOME/network/admin/tnsnames.ora"
su -l oracle -c "echo '$ORACLE_PDB= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_PDB)
  )
)' >> $ORACLE_HOME/network/admin/tnsnames.ora"

# Start LISTENER
su -l oracle -c "lsnrctl start"

echo 'INSTALLER: Listener created'

# Create database

# Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=K2ypton55

cp /vagrant/ora-response/dbca.rsp.tmpl /vagrant/ora-response/dbca.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /vagrant/ora-response/dbca.rsp
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" /vagrant/ora-response/dbca.rsp
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" /vagrant/ora-response/dbca.rsp
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" /vagrant/ora-response/dbca.rsp
sed -i -e "s|###EM_EXPRESS_PORT###|$EM_EXPRESS_PORT|g" /vagrant/ora-response/dbca.rsp

# Create DB
printf 'Creating database ...\r\n'
su -l oracle -c "dbca -silent -createDatabase -responseFile /vagrant/ora-response/dbca.rsp"

# Post DB setup tasks
su -l oracle -c "sqlplus / as sysdba <<EOF
   ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE;
   EXEC DBMS_XDB_CONFIG.SETGLOBALPORTENABLED (TRUE);
   ALTER SYSTEM SET LOCAL_LISTENER = '(ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT))' SCOPE=BOTH;
   ALTER SYSTEM REGISTER;
   exit;
EOF"

rm /vagrant/ora-response/dbca.rsp

echo 'INSTALLER: Database created'

# Remove temporary beq auth service in sqlnet.ora
su -l oracle -c "yes|sed -e '/BEQ/d' -i $ORACLE_HOME/network/admin/sqlnet.ora"

# Get RU metadata
su -l oracle -c "sqlplus / as sysdba <<EOF
set line 300
col action form a12
col version  form a40
col description form a60
col action_date form a20
select description, action, to_char(action_time,'DD/MM/RR HH24:MI:SS') action_date, ' ' version from dba_registry_sqlpatch;
   exit;
EOF"

sed '$s/N/Y/' /etc/oratab | sudo tee /etc/oratab > /dev/null
echo 'INSTALLER: Oratab configured'

# configure systemd to start oracle instance on startup
sudo cp /vagrant/scripts/oracle-rdbms.service /etc/systemd/system/
sudo sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /etc/systemd/system/oracle-rdbms.service
sudo systemctl daemon-reload
sudo systemctl enable oracle-rdbms
sudo systemctl start oracle-rdbms
echo "INSTALLER: Created and enabled oracle-rdbms systemd's service"

# setup sys password
sudo cp /vagrant/scripts/setPassword.sh /home/oracle/
sudo chmod a+rx /home/oracle/setPassword.sh
echo "INSTALLER: setPassword.sh file setup";
su -l oracle -c "/home/oracle/setPassword.sh $ORACLE_PWD"

echo "ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: $ORACLE_PWD";

echo "INSTALLER: Installation complete, database ready to use!";
