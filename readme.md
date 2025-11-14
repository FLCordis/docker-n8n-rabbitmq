# Docker Compose with N8N + RabbitMQ and PostgreSQL (Admire)
First, install the Node modules
```
npm install
```

Second, configure the local HTTPS license and change the users if you want, then just upload the containers.
```
openssl req -x509 -nodes -newkey rsa:2048 -keyout n8n.key -out n8n.crt -days 365
```

Create the enviroment file with .env
```
RABBIT_HOST=
RABBIT_PORT=5672
RABBIT_USER=
RABBIT_PASS=
RABBIT_PROTOCOL=amqp
RABBIT_QUEUE=
```

## Start the containers
Upload the containers with `docker-compose.yml`
```
docker-compose -f config/docker-compose.yml up -d
```

## Environments
| Service       | Address                 | Login / Password   
| ------------- |:-----------------------:|:------------------:|
| n8n           | https://localhost:5678  | admin / adminpass   
| RabbitMQ UI   | http://localhost:15672  | n8n / n8npass
| Adminer (DB)  | http://localhost:8080   | postgres / n8n / n8npass / n8n_db

## Automatic backups
Script execution permission
```
chmod +x backup.sh
```
Open cron and:
```
crontab -e
```
Then add the line at the end:
```
0 3 * * 1 cd path/your-project && path/your-project/backup.sh backup >> path/your-project/backup/cron.log 2>&1
```
This does the following:
* Runs every Monday at 3 a.m.;
* Saves the log in `backup/cron.log`.

### Manual backup
```
./backup.sh backup
```
### Restore backups 
```
./backup.sh restore <file>
```