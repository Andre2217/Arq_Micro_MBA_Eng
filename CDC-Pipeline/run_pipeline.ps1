Write-Host "Aguardando Kafka Connect iniciar..."

$maxAttempts = 20
$attempt = 1

while ($attempt -le $maxAttempts) {
    $response = curl.exe -s http://localhost:8083/connectors
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Kafka Connect esta pronto!"
        break
    }
    Start-Sleep -Seconds 5
    $attempt++
}

if ($attempt -gt $maxAttempts) {
    Write-Host "Kafka Connect nao iniciou. Abortando script."
    exit 1
}

Write-Host "Aguardando Postgres SOURCE..."
$ready = $false
while (-not $ready) {
    try {
        docker exec -i cdc-pipeline-postgres-source-1 psql -U postgres -d source_db -c "SELECT 1;" | Out-Null
        $ready = $true
    } catch {
        Start-Sleep -Seconds 5
    }
}


Write-Host "Exibindo os dados no Source"
docker exec -it cdc-pipeline-postgres-source-1 psql -U postgres -d source_db -c "SELECT * FROM customers ORDER BY id;"


Write-Host "Registrando conectores..."
curl.exe -X POST -H "Content-Type: application/json" --data @connectors/register_postgres_source.json http://localhost:8083/connectors | jq
Write-Host "`n"
curl.exe -X POST -H "Content-Type: application/json" --data @connectors/postgres-sink-connector.json http://localhost:8083/connectors | jq
Write-Host "`n"
curl.exe -X POST -H "Content-Type: application/json" --data @connectors/sink-minio.json http://localhost:8083/connectors | jq

Write-Host "`nVerificando os conectores"    
curl.exe http://localhost:8083/connectors

# Write-Host "`nListar topicos kafka"
# docker exec -it cdc-pipeline-kafka-1 kafka-topics --bootstrap-server kafka:9092 --list 

# Write-Host "`n Verificando mesnagens no topico cdc.public.custumers"
# docker exec -it cdc-pipeline-kafka-1 kafka-console-consumer --bootstrap-server kafka:9092 --topic cdc.public.customers --from-beginning --max-messages 10

Write-Host "Rodando mutacoes..."
docker exec -i cdc-pipeline-postgres-source-1 psql -U postgres -d source_db -f /scripts/mutations.sql

Write-Host "Exibindo SOURCE apos mutacoes:"
docker exec -it cdc-pipeline-postgres-source-1 psql -U postgres -d source_db -c "SELECT * FROM customers ORDER BY id;"
