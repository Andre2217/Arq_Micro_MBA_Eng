# Manual Operacional – CDC Pipeline
(Guia de Diagnóstico, Operação e Troubleshooting)

Este documento complementa o README principal e serve como uma referência para investigação de falhas, verificação manual dos serviços e depuração geral do pipeline de CDC.
Como o projeto pode sofrer alterações, nomes de conectores, serviços e arquivos mencionados aqui podem não refletir perfeitamente seu estado atual — trate-os como exemplos.

## 📦 Componentes do Pipeline

O ambiente é composto por:

- Postgres (fonte e destino) – origem dos eventos CDC e/ou repositório final.

- Kafka – barramento de eventos e armazenamento dos registros CDC.

- Schema Registry – gerenciamento de schemas Avro/JSON usados nos tópicos.

- Debezium / Kafka Connect – captura das mudanças e publicação/consumo.

- MinIO – armazenamento de arquivos Parquet (sink S3).

- Scripts SQL – carga inicial, mutações e consultas.

- Conectores – arquivos JSON que definem o comportamento do Debezium e dos sinks.

Cada parte pode falhar independentemente, então o manual abaixo separa o diagnóstico por componente.

## 🔍 1. Diagnóstico de Kafka & Infraestrutura
Verificar se Kafka está em execução
```bash
docker compose ps
```
Procure o container kafka ativo.

### Listar tópicos disponíveis
```sh 
docker exec -it <container-kafka> kafka-topics --bootstrap-server kafka:9092 --list
```

Se o tópico de CDC não estiver listado, geralmente indica:

- conector Debezium não registrou

- Debezium não conseguiu conectar no Postgres

- Postgres fonte não está com `wal_level=logical`

### Consumir mensagens manualmente

```bash
docker exec -it <container-kafka> kafka-console-consumer \
  --bootstrap-server kafka:9092 \
  --topic <topico-do-cdc> \
  --from-beginning \
  --max-messages 10
```
Se o consumidor não receber nada:

- Debezium não enviou eventos

- nenhum dado mudou na fonte

- o conector falhou após criação

### Logs úteis do Kafka

```bash
docker compose logs kafka --tail=200
docker compose logs schema-registry --tail=200
```

## 🔧 2. Diagnóstico de Debezium & Conectores

### Verificar conectores registrados
```bash
curl http://localhost:8083/connectors
```

Se aparecer vazio, Kafka Connect não está configurado corretamente ou ainda está inicializando.

### Verificar status de um conector
```bash
curl http://localhost:8083/connectors/<nome-do-conector>/status
```

Estados importantes:

- RUNNING → ativo

- FAILED → falha no processamento

- UNASSIGNED → serviço ainda subindo ou reiniciando

- PAUSED → manualmente pausado

### Recarregar um conector (quando a config mudou)
```bash
curl -X DELETE http://localhost:8083/connectors/<nome>
curl -X POST -H "Content-Type: application/json" --data @connectors/<arquivo>.json http://localhost:8083/connectors
```
### Problemas comuns no conector Debezium (fonte)

- wal_level incorreto

- usuário sem permissão em replication slots

- plugin errado (plugin.name=pgoutput)

- banco de origem não está acessível

- container Postgres não subiu ou está reiniciando

### Problemas comuns nos sinks

- JDBC Sink → URL inválida, falta de schema, credenciais erradas

- MinIO/S3 Sink → chaves inválidas, bucket inexistente, endpoint errado

### Logs do Kafka Connect / Debezium
```bash
docker compose logs connect --tail=300
```
## 🗄️ 3. Diagnóstico de Postgres (fonte e destino)
### Acessar o Postgres fonte
```bash
docker exec -it <pg-source> psql -U postgres -d <source_db>
```
### Checar tabelas e dados iniciais
```sql
SELECT * FROM <tabela>;
```
Se a tabela estiver vazia:

- a carga inicial pode não ter sido executada

- volume foi recriado

- script SQL não rodou

### Executar manualmente os scripts

```bash
docker exec -i <pg-source> psql -U postgres -d <source_db> -f /scripts/init_source.sql
docker exec -i <pg-source> psql -U postgres -d <source_db> -f /scripts/mutations.sql
```
### Conferir replicação lógica habilitada
```sql
SHOW wal_level;
SHOW max_replication_slots;
```
Idealmente:

- `wal_level = logical`
- `max_replication_slots >= 1`

## 🪣 4. Diagnóstico de MinIO & Sink S3
### Acessar a interface web
```bash
http://localhost:9001
```
Credenciais:

- usuário: minio

- senha: minio123

### Confirmar o bucket necessário

Crie o bucket usado pelo sink (geralmente `data`, mas depende da configuração atual do projeto).

### Verificar se arquivos estão aparecendo

Dentro do bucket:

- procure uma pasta com o nome do tópico do Kafka

- dentro dela, arquivos .parquet (ou outro formato configurado)

## 🔥 5. Troubleshooting Geral (Guia Rápido)

### Nada está sendo replicado

1. Verifique se Debezium está RUNNING

2. Confirme os tópicos Kafka

3. Execute uma mutação manual no Postgres

4. Veja se mensagens aparecem no tópico

5. Verifique sinks (status + logs)

### Conector aparece como FAILED

- olhe os logs do Connect

- problema quase sempre é config inválida, credenciais erradas ou endpoint inacessível

### MinIO não recebe arquivos

- bucket ausente

- permissões incorretas

- flush.size muito alto

- falha na conversão para Parquet (ver logs do sink)

### Postgres destino não recebe nada

- URI JDBC errada

- schema/table esperada não existe

- o conector foi registrado com nome diferente

- autenticador inválido

### Kafka sem tópicos CDC

- Debezium não registrou ou falhou

- fonte não tem wal_level=logical

- Debezium não conseguiu criar replicação

## 🧹 6. Limpeza e Reset de Ambiente
### Parar containers
```bash
docker compose down
```
### Reset completo (remove volumes)
```bash
docker compose down -v
```
Use isso se quiser reconstruir a base inteira, recarregar dados e reinscrever conectores.
## 📝 7. Observação Importante
Os nomes de serviços, conectores e arquivos JSON variam conforme a versão do projeto.
Use os exemplos deste manual como guias de diagnóstico, não como a estrutura exata do seu ambiente.








