#!/bin/bash

set -eu

check_port() {
    local port="$1"

    if ss -ltn | grep -q ":$port "; then
        read -rp "Um serviço está utilizando a porta $port. Deseja desativá-lo? (s/N) " response
        response=${response,,}

        if [[ "$response" == "s" ]]; then
            sudo fuser -k "$port"/tcp
            echo "Porta $port liberada."
        else
            echo "Abortando..."
            exit 1
        fi
    fi
}


echo "Verificando se existe algum serviço ocupando as portas que serão usadas para os containers..."
check_port "5432"
check_port "5050"

echo "Rodando o docker compose com os containers do postgres e pgAdmin4..."
if ! command -v docker >/dev/null 2>&1; then
    echo "Docker não instalado. https://docs.docker.com/engine/install/"
    exit 1
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    echo "O docker compose não está instalado. https://docs.docker.com/compose/"
    exit 1
fi

$COMPOSE_CMD up -d

echo -e "\n\e[1;32m===============================================\e[0m"
echo -e "\e[1;32m   ✔ BANCO DE DADOS LOCAL DO CDA WEB INICIALIZADO\e[0m"
echo -e "\e[1;32m===============================================\e[0m\n"

echo -e "\e[1;34mBanco de dados PostgreSQL disponível via Docker\e[0m"
echo -e "\e[1;37m• Host:\e[0m localhost"
echo -e "\e[1;37m• Porta:\e[0m 5432\n"

echo -e "\e[1;34mAcesso ao pgAdmin4:\e[0m"
echo -e "\e[1;37m• URL:\e[0m http://localhost:5050\n"

echo -e "\e[1;33mUse as credenciais definidas no docker-compose.yml\e[0m"
echo -e "\e[1;32mBom desenvolvimento! 🚀\e[0m\n"