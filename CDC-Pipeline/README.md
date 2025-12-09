# CDC Pipeline – Replicação de Dados com Kafka + Debezium + MinIO

Este projeto implementa um pipeline reprodutível de Captura de Dados de Mudança (CDC) usando Kafka, Debezium e múltiplos destinos.
A estrutura está preparada para replicar alterações de um banco Postgres para diferentes consumidores — incluindo armazenamento em objetos no MinIO em formato Parquet.

## 📁 Estrutura do Projeto

```bash
cdc-pipeline/
│
├── connectors/
│   ├── postgres-sink-connector.json
│   ├── register_postgres_source.json
│   └── sink-minio.json
│
├── scripts/
│   ├── init_source.sql
│   └── mutations.sql
│
├── .env
├── docker-compose.yml
└── run_pipeline.ps1
```
## 🚀 Como Executar o Pipeline

### 1. Subir toda a stack com Docker
Entre na pasta do projeto e execute:
```sh
docker compose up -d --build
```
Isso iniciará:
- Kafka + Schema Registry

- Debezium Connect

- Postgres (com carga inicial automática)

- MinIO

- Outros serviços necessários para o pipeline

### 2. Criar o bucket data no MinIO

Acesse a interface administrativa do MinIO:

👉 http://localhost:9001/

Usuário: `minio`
Senha: `minio123`

Crie um bucket chamado `data`

Esse bucket será utilizado pelos sinks que gravam arquivos Parquet.

### 3. Rodar o pipeline automaticamente

Use o script PowerShell incluído no projeto:

`./run_pipeline.ps1`

Este script executa o fluxo completo:

1. Aguarda Kafka e Postgres ficarem prontos

2. Exibe os dados iniciais da tabela fonte

3. Registra os três conectores (source + sinks)

4. Lista os conectores registrados

5. Aplica as mutações definidas em `mutations.sql`

6. Mostra o estado atualizado do banco após as alterações

Ao final, os eventos CDC são enviados para o Kafka e processados pelos sinks.

### 4. Verificar os arquivos no MinIO

Retorne ao MinIO, atualize a página, abra o bucket data e você verá os arquivos Parquet gerados automaticamente.

## Evidências de Execução

Todas as evidências necessárias para validação do pipeline são exibidas automaticamente pelo script run_pipeline.ps1.
Ao rodar o script, são mostrados em tempo real:

- Verificação de disponibilidade dos serviços (Postgres, Kafka, Connect, MinIO)

- Exibição dos dados iniciais na base fonte

- Registro dos conectores (source e sinks)

- Listagem dos conectores ativos

- Execução das mutações (INSERT, UPDATE e DELETE)

- Exibição dos dados na tabela fonte após as mutações

Essas saídas constituem as evidências de execução solicitadas no trabalho, demonstrando todo o fluxo do CDC funcionando de ponta a ponta.

E toda outro comando para obter qualquer outro tipo de evidencia pode ser facilmente encontrado no arquivo `manual-operacioanl.md`

## 🧹 Como limpar tudo

Para remover containers, volumes e estado:
```sh
docker compose down -v
```

Isso reseta completamente a stack, permitindo reexecutar o pipeline desde o início.
