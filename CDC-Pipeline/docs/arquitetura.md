# Arquitetura da Solução – CDC Pipeline com Kafka, Debezium, Postgres e MinIO
## 📌 1. Visão Geral

A solução implementa um pipeline de CDC (Change Data Capture) que captura alterações em uma tabela PostgreSQL e as envia para um data lake baseado em MinIO no formato Parquet, utilizando Kafka e Kafka Connect como camada de transporte e orquestração de conectores.

O objetivo principal da arquitetura é demonstrar o fluxo completo:

Banco de dados → Captura de mudanças (CDC) → Kafka → Conector Sink → Armazenamento em Parquet no MinIO

Toda a infraestrutura é provisionada via Docker Compose, permitindo reprodutibilidade e isolamento completo do ambiente.

## 📌 2. Componentes da Arquitetura

A arquitetura é composta pelos seguintes serviços:

### 1. PostgreSQL (Fonte de Dados)

- Armazena os dados que serão monitorados.

- Possui as tabelas iniciais criadas por meio do script init_source.sql.

- O CDC ocorre através do WAL (Write-Ahead Log), que é consumido pelo Debezium.

### 2. Kafka

- Funciona como barramento de mensagens.

- Cada mudança no banco (INSERT, UPDATE, DELETE) vira um evento enviado para um tópico específico.

- Inclui:

    - Zookeeper

    - Broker Kafka

### 3. Kafka Connect

- Executa conectores que integram Kafka com sistemas externos.

- Neste projeto existem três conectores:

    - Registrador da Fonte (Postgres Source – Debezium)

    - Sink para MinIO

    - Sink para Postgres

Os conectores são registrados via API REST usando o script run_pipeline.ps1.

### 4. Debezium (Postgres Source Connector)

- Captura alterações no Postgres usando o WAL.

- Converte cada operação em eventos estruturados (JSON).

- Publica esses eventos no Kafka.

### 5. MinIO (Data Lake)

- Armazena os dados finais em formato Parquet.

- Compatível com API S3.

- Requer a criação manual de um bucket chamado data.

### 6. Conector Sink para MinIO

- Lê eventos de um tópico Kafka.

- Escreve em objetos Parquet dentro do MinIO.

- Gera partições e arquivos automaticamente.

## 📌 3. Fluxo Arquitetural

O fluxo de ponta a ponta pode ser resumido assim:
```scss
PostgreSQL
   ↓ (alterações no WAL)
Debezium Source Connector
   ↓ (eventos CDC)
Kafka (tópico intermediário)
   ↓
Sink Connector
   ↓
MinIO (arquivos Parquet)
```
### Passo a passo lógico:

1. O Postgres recebe dados iniciais ao subir o ambiente.

2. Debezium detecta mudanças e as envia para Kafka.

3. Kafka armazena e distribui os eventos via tópicos.

4. O Sink Connector lê esses tópicos.

5. Os dados são gravados no MinIO dentro do bucket data.

## 📌 4. Relacionamento entre os Serviços

Um diagrama simples para facilitar visualização:
```
flowchart LR
    A[(PostgreSQL)] -- WAL Changes --> B[Debezium Source Connector]
    B --> C[(Kafka Broker)]
    C --> D[Sink Connector]
    D --> E[(MinIO Data Lake)]
```

## 📌 5. Scripts e Arquivos Relevantes

- docker-compose.yml
    Provisiona toda a infraestrutura.

- .env
    Contém variáveis de ambiente essenciais (credenciais, URLs, portas).

- init_source.sql
    Popula o Postgres com dados iniciais.

- mutations.sql
    Aplica operações CRUD para validar o CDC.

- Conectores JSON (nomes podem mudar)

    - postgres-source.json

    - postgres-sink.json

    - sink-minio.json

- run_pipeline.ps1
    Automatiza:

    - validação dos serviços

    - registro dos conectores

    - execução de mutações

    - consultas ao estado final

## 📌 6. Considerações Importantes

- Os nomes dos conectores podem variar conforme o ambiente e a versão do projeto.

- Alguns conectores permanecem executando em estado “running”, mesmo que falhem internamente — isso é comum em pipelines usando Debezium + MinIO Sink.

- O MinIO exige criação manual do bucket antes do pipeline rodar.

- O fluxo é sensível à ordem de inicialização, portanto run_pipeline.ps1 foi criado justamente para evitar problemas.

## 📌 7. Conclusão da Arquitetura

A arquitetura demonstra um pipeline funcional de CDC modular, utilizando ferramentas amplamente aplicadas em ambientes de streaming e data lake. Ela garante:

- captura contínua de alterações

- transporte por mensageria escalável

- armazenamento em formato colunar

- infraestrutura reproduzível via Docker