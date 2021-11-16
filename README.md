# MySQL-Backup-Restore
MySQL-backup-restore is a docker image that can be used for backup/restore/store of a mysql-database (5.6, 5.7, 8.0) dump. Dump is done before database is initialized, and a test-instance is instanciated with the dump, and tested with sql provided in .sql-file. If no error occur the dump is uploaded to either Azure Storage or AWS S3. Everything is configured in .env-file, see more on .env-file below.

# .sql file
Add new or use existing .sql-file for specific environment. SQL runs after initialization and it's supposed to be used as a test that assure that database dump is valid. Environment specific .sql-files is provided under ./tests. To make MySQL throw exception, use "SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Message'", which will make the job fail and "Message" will end up as a error-message in log.

# .env file
Add new .env-file with vars for specific environment. Name of .env file is used as name of job in log.

*	DUMP_HOST - hostname of MySQL-server to dump
*	DUMP_USER - username to MySQL-server user
*	DUMP_PASSWD - password to MySQL-server user
*	DUMP_NAME - name of dump. Used when dump is uploaded to Azure/AWS. I.e. <dump_name>.<datetime>.sql.gz.aes
*   DUMP_DATABASES - schemas to dump. Regular expression used. If empty, all schemas except system-schemas will be dumped.
Example: ^database-name-begins-with|^exact-database-name$

*   ENC_PASSWD - password key to use when encryping.
*   AZ_STORAGE_KEY - SAS -token URL to Azure Storage Blob. If not set dump is not uploaded

# Run

``` bash
./backup-restore.sh "env-file-name.env" "full-path-to-sql-test-file" "version: 8.0|5.6|5.7"
```

Logs are written to $HOME/backup-restore/backup-restore.log.

Before scheduling script, image needs to be pulled for tag/version used.

## On fail 
Container log is saved to "env-file-name"."date".log. And container is not removed (container name = "env-file-name"). Also volume is not removed (volume name = "env-file-name"). For further investigation.  

# Report mailer (MailJet)

``` bash
./backup-restore-mailer.sh "(opt) path-to-log"
```
Set vars in script. Can be found in Mailjet API Key Management.

``` bash
MJ_APIKEY_PUBLIC="api-key"
MJ_APIKEY_PRIVATE="secret-key"
```

backup-restore-mailer.sh traverses main logfile created by backup-restore.sh. Default log path is $HOME/backup-restore/backup-restore.log. So per default it depends on which users used when running the script.

# Encryption
AES 256 bit CBC encryption is used.With sha512 hash.

Openssl is used to encrypt. openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt.

5.6 only has openssl enc -aes-256-cbc -md sha512, due to openssl-1.1.0 limitations.

## Decrypt 
### 8.0
``` bash
openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -in "path-to-encrypted-file" -out "path-to-decrypted-file"
```

### 5.6-6.7
``` bash
openssl enc -aes-256-cbc -md sha512 -d  -d -in "path-to-encrypted-file" -out "path-to-decrypted-file"
```

# MySQLd settings
MySQLd is optimized to use maximum 3GB memory. And settings is in docker.conf-file. If tmpdir or datadir need to be set, a new conf-file must be copied to /etc/mysql/mysql.conf.d/mysqld.cnf.

# Links

[MySQL docker](https://hub.docker.com/_/mysql)

[MySQL git](https://github.com/docker-library/mysql)