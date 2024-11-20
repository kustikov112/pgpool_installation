
```
curl -L -o pgpool_source.tar.gz https://www.pgpool.net/mediawiki/download.php?f=pgpool-II-4.5.2.tar.gz
yum in -y postgresql15-server postgresql15-server-devel gcc make amazon-efs-utils

cd pgpool-II-4.5.2/
./configure CPPFLAGS="-I/usr/include/pgsql" --prefix=/usr/ --sysconfdir=/etc/pgpool-II/ --with-openssl
make
make install

mkdir /var/run/pgpool
chown -R postgres:postgres /var/run/pgpool
if [ $? -ne 0 ]; then
    chown -R postgres:users /var/run/pgpool
    fi

mv src/redhat/pgpool.service /etc/systemd/system/
cd src/sql/pgpool-recovery/
make
make install

mkdir  /var/lib/pgsql/archivedir/
chown postgres:postgres  /var/lib/pgsql/archivedir/
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 10.0.1.134:/  /var/lib/pgsql/archivedir/

su postgres
initdb -D /var/lib/pgsql/data
mkdir /tmp/pgsql_log
```
#### REPLACE DATA FOR POSTGRESQL.CONF
#### ADD this strings to pg_hba.conf
```
host    replication	all		10.0.0.0/8		trust
host all		all		10.0.0.0/8		trust
```
```
exit
systemctl start postgresql
su postgres
psql -c "create user pgpool with password 'secure_pass'"
psql -c "alter user pgpool with replication"
psql -c "alter user pgpool with superuser"

exit
```
#### PGPOOL CONFIG OWNAGE
```
chmod -R 744 /etc/pgpool-II
chown -R postgres:postgres /etc/pgpool-II
if [ $? -ne 0 ]; then
    chown -R postgres:users /etc/pgpool-II
    fi
```
#### KEYS
```
su - postgres
mkdir ~/.ssh
chmod 700 ~/.ssh
cd ~/.ssh
ssh-keygen -t rsa -f id_rsa
touch ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys 
chown postgres:postgres ~/.ssh/authorized_keys
if [ $? -ne 0 ]; then
    chown -R postgres:users ~/.ssh/authorized_keys
    fi
```
#### COPY PUB PARTS FROM id_rsa.pub to auth_keys of both machines

#### PGPASS
```
vi /var/lib/pgsql/.pgpass
```
```
localhost:5432:*:postgres:pg_password
10.0.1.96:5432:*:postgres:pg_password
10.0.1.123:5432:*:postgres:pg_password
10.0.1.80:5432:*:postgres:pg_password

10.0.1.96:5432:*:pgpool:secure_pass
10.0.1.123:5432:*:pgpool:secure_pass
10.0.1.80:5432:*:pgpool:secure_pass

10.0.1.96:9999:*:postgres:pg_password
10.0.1.123:9999:*:postgres:pg_password
10.0.1.80:9999:*:postgres:pg_password

localhost:9999:*:pgpool:secure_pass
10.0.1.96:9999:*:pgpool:secure_pass
10.0.1.123:9999:*:pgpool:secure_pass
10.0.1.80:9999:*:pgpool:secure_pass
```
```
chmod 600 /var/lib/pgsql/.pgpass
```
#### PGCONFIG
```
cd /etc/pgpool-II
mv pool_hba.conf.sample pool_hba.conf
mv pgpool.conf.sample pgpool.conf
mv pcp.conf.sample pcp.conf
mv follow_primary.sh.sample follow_primary.sh
mv failover.sh.sample failover.sh
mv pgpool_remote_start.sample pgpool_remote_start
mv recovery_1st_stage.sample recovery_1st_stage
```
#### Update pgpool.conf data on all machines
#### ADD this to pool_hba.conf
```
host all		all		10.0.0.0/8		trust
```

#### SCRAM POOL_PASS
```
echo “secure_pool_key” > ~/.pgpoolkey
chmod 600 ~/.pgpoolkey
pg_enc -m -k ~/.pgpoolkey -u pgpool -p -f /etc/pgpool-II/pgpool.conf
```
#### PCPPASS
```
echo 'pgpool:''pg_md5 secure_pass' >> /etc/pgpool-II/pcp.conf
```
```
vi ~/.pcppass
```
```
localhost:9888:postgres:pg_password
10.0.1.96:9888:pgpool:secure_pass
10.0.1.123:9888:pgpool:secure_pass
10.0.1.80:9888:pgpool:secure_pass
```
```
chmod 600 ~/.pcppass
```
#### ONLINE RECOVERY
```
cp -p /etc/pgpool-II/recovery_1st_stage /var/lib/pgsql/data/recovery_1st_stage
cp -p /etc/pgpool-II/pgpool_remote_start /var/lib/pgsql/data/pgpool_remote_start
chown postgres:postgres /var/lib/pgsql/data/{recovery_1st_stage,pgpool_remote_start}
chmod +x /var/lib/pgsql/data/recovery_1st_stage
chmod +x /var/lib/pgsql/data/pgpool_remote_start
```
#### LOGS
```
mkdir /tmp/pgpool_logs
chown postgres:postgres /tmp/pgpool_logs
if [ $? -ne 0 ]; then
	chown postgres:users /tmp/pgpool_logs
    fi
```
#### NODE_ID and status
```
echo 2 > pgpool_node_id
touch /tmp/pgpool_status
chown postgres:postgres /tmp/pgpool_status
if [ $? -ne 0 ]; then
	chown postgres:users /tmp/pgpool_status
    fi
chmod 644 /tmp/pgpool_status

psql template1 -c "CREATE EXTENSION pgpool_recovery"
```
```
vi /etc/systemd/system/pgpool.service
```
```
[Unit]
Description=Pgpool-II
After=syslog.target network.target

[Service]
Type=forking
User=postgres
Group=postgres

ExecStart=/usr/bin/pgpool -f /etc/pgpool-II/pgpool.conf -F  /etc/pgpool-II/pcp.conf --hba-file=/etc/pgpool-II/pool_hba.conf
PIDFile=/var/run/pgpool/pgpool.pid

[Install]
WantedBy=multi-user.target
```

systemctl enable pgpool.service

ldconfig - to reload LIBS on VM if pgpool or pg_enc won't start. 
