# Docker Compose com N8N + RabbitMQ e PostgreSQL (Admire)
Basta configurar a licença do HTTPS local e trocar os usuários caso desejar, depois só subir os containers.
```
openssl req -x509 -nodes -newkey rsa:2048 -keyout n8n.key -out n8n.crt -days 365
```

## Iniciar os containers
Subir os containers com o `docker-compose.yml`
```
docker compose up -d
```

## Ambientes
| Serviço       | Endereço                | Login / Senha
| ------------- |:-----------------------:|:------------------:| 
| n8n           | https://localhost:5678  | admin / adminpass
| RabbitMQ UI   | http://localhost:15672  | n8n / n8npass
| Adminer (DB)  | http://localhost:8080   | postgres / n8n / n8npass / n8n_db


## Backups automáticos
Permissão de execução do script
```
chmod +x backup.sh
```

Abra o cron e:
```
crontab -e
```
Depois adicione a linha no final:
```
0 3 * * 1 cd caminho/seu-projeto && caminho/seu-projeto/backup.sh backup >> caminho/seu-projeto/backup/cron.log 2>&1
```

Isso faz:
* rodar toda segunda-feira às 3h da manhã;
* guardar o log em `backup/cron.log`.

### Backup manual
```
./backup.sh backup
```

### Restaurar backups 
```
./backup.sh restore <arquivo>
```