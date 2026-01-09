#!/bin/bash
set -euo pipefail

CDA_WEB_ENV_DIR="$HOME/cda-web-env-dir"

TOMCAT_VERSION="10.1.50"
TOMCAT_NAME="apache-tomcat-$TOMCAT_VERSION"
TOMCAT_TAR="$TOMCAT_NAME.tar.gz"
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-10/v$TOMCAT_VERSION/bin/$TOMCAT_TAR"

SDKMAN_URL="https://get.sdkman.io?ci=true&rcupupdate=false"
SDKMAN_DIR="$HOME/.sdkman"
JAVA_VERSION="17.0.10-tem"
MAVEN_VERSION="3.9.9"

CDA_WEB_REPORTS_MANAGER_URL="https://github.com/dev-cda/cda-web-reports-manager.git"
CDA_WEB_REPORTS_MANAGER_DIR="$CDA_WEB_ENV_DIR/cda-web-reports-manager"
CDA_WEB_REPORTS_MANAGER_BRANCH="update-for-tomcat-10"

CDA_WEB_PROJECT_URL="https://github.com/dev-cda/cda-web.git"
CDA_WEB_PROJECT_DIR="$CDA_WEB_ENV_DIR/cda-web"

CDA_API_URL="https://github.com/dev-cda/cda-api.git"
CDA_API_DIR="$CDA_WEB_ENV_DIR/cda-api"

dir_not_exists() {
  [[ ! -d $1 ]] 
}

echo "Criando diretório para ambiente do projeto..."
if dir_not_exists "$CDA_WEB_ENV_DIR"; then
  mkdir -p "$CDA_WEB_ENV_DIR" 
else
  echo "Diretório já existe!"
fi

cd "$CDA_WEB_ENV_DIR" || exit 1

echo "Instalando e descompactando Apache Tomcat..."
if dir_not_exists "$TOMCAT_NAME"; then
  curl -fLo "$TOMCAT_TAR" "$TOMCAT_URL"
  tar -xzf "$TOMCAT_TAR"
  rm "$TOMCAT_TAR"
fi

chmod +x "$TOMCAT_NAME"/bin/*.sh

echo "Instalando o SDKMAN! para instalação e gerenciamento do JDK e do Maven..."
if dir_not_exists "$SDKMAN_DIR"; then
  curl -s "$SDKMAN_URL" | bash
else
  echo "SDKMAN! já instalado"
fi

source "$SDKMAN_DIR/bin/sdkman-init.sh"

echo "Verificando se o JDK 17 está instalado na sua máquina(mais especificamente o $JAVA_VERSION)..."
if sdk list java | grep -q "$JAVA_VERSION"; then
  if sdk current java 2>/dev/null | grep -q "$JAVA_VERSION"; then
    echo "JDK já instalado e na versão correta!"
  else
    echo "JDK instalado, mas não ativo. Ativando..."
    sdk use java "$JAVA_VERSION"
  fi
else
  echo "JDK $JAVA_VERSION não encontrado. Instalando..."
  sdk install java "$JAVA_VERSION"
  sdk use java "$JAVA_VERSION"
fi

echo "Verificando se o Maven $MAVEN_VERSION está instalado na sua máquina..."
if sdk list maven | grep -q "$MAVEN_VERSION"; then
  if sdk current maven 2>/dev/null | grep -q "$MAVEN_VERSION"; then
    echo "Maven já instalado!"
  else
    echo "Ativando Maven $MAVEN_VERSION..."
    sdk use maven "$MAVEN_VERSION"
  fi
else
  echo "Maven $MAVEN_VERSION não encontrado. Instalando..."
  sdk install maven "$MAVEN_VERSION"
  sdk use maven "$MAVEN_VERSION"
fi

echo "Clonando o repositório do CDA Web Reports Manager(dependência do CDA Web)"
if dir_not_exists "$CDA_WEB_REPORTS_MANAGER_DIR"; then
  git clone "$CDA_WEB_REPORTS_MANAGER_URL"
fi

cd "$CDA_WEB_REPORTS_MANAGER_DIR"
git fetch origin
git checkout "$CDA_WEB_REPORTS_MANAGER_BRANCH"
mvn install -DskipTests=true
cd "$CDA_WEB_ENV_DIR"

if dir_not_exists "$CDA_WEB_PROJECT_DIR"; then
  git clone "$CDA_WEB_PROJECT_URL"
fi
    
if dir_not_exists "$CDA_API_DIR"; then
  git clone "$CDA_API_URL"
fi
