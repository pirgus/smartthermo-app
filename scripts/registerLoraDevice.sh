#!/bin/bash

# Verifica se o arquivo .env existe
if [ ! -f .env ]; then
    echo "Erro: Arquivo .env não encontrado."
    echo "Crie um arquivo .env baseado no .env.template e preencha com suas credenciais."
    exit 1
fi

# Carrega as variáveis do .env
source .env

# Verifica variáveis obrigatórias
if [ -z "$DEVICE_ID" ] || [ -z "$APP_EUI" ] || [ -z "$DEV_EUI" ] || [ -z "$APPLICATION_ID" ] || [ -z "$APPLICATION_KEY" ]; then
    echo "Erro: Variáveis obrigatórias não definidas no .env"
    exit 1
fi

# Verifica se SERVICE_PATH está definido
if [ -z "$SERVICE_PATH" ]; then
    echo "Erro: Variável SERVICE_PATH não definida no .env"
    exit 1
fi

# Faz a requisição POST para o FIWARE
echo "Registrando dispositivo $DEVICE_ID no FIWARE..."
echo

response=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" \
--location --request POST 'http://localhost:4041/iot/devices' \
--header 'fiware-service: openiot' \
--header "fiware-servicepath: $SERVICE_PATH" \
--header 'Content-Type: application/json' \
--data-raw '{
    "devices": [
        {
            "device_id": "'"$DEVICE_ID"'",
            "entity_name": "'"$ENTITY_NAME"'",
            "entity_type": "LoraDevice",
            "attributes": [
                { "object_id": "Temperatura", "name": "Temperatura", "type": "Float"},
                { "object_id": "Umidade", "name": "Umidade", "type": "Float"}
            ],
            "internal_attributes": {
                "lorawan": {
                    "application_server": {
                        "host": "'"$APP_SERVER_HOST"'",
                        "username": "'"$APP_SERVER_USERNAME"'",
                        "password": "'"$APP_SERVER_PASSWORD"'",
                        "provider": "TTN"
                    },
                    "app_eui": "'"$APP_EUI"'",
                    "dev_eui": "'"$DEV_EUI"'",
                    "application_id": "'"$APPLICATION_ID"'",
                    "application_key": "'"$APPLICATION_KEY"'",
                    "data_model": "'"$DATA_MODEL"'"
                }
            }
        }
    ]
}')

# Extrai resposta e código de status
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
status=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [ "$status" -ne 201 ]; then
    echo "Erro ao registrar dispositivo: HTTP $status"
    echo "Resposta do servidor:"
    echo "$body"
    exit 1
else
    echo "Dispositivo registrado com sucesso!"
fi
