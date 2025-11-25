#!/bin/bash

###############################################################################
# GCP DIAGNOSTIC SCRIPT - Encuentra tu cluster y proyecto correcto
###############################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        GCP DIAGNOSTIC - Encuentra tu cluster          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar autenticación
echo -e "${YELLOW}🔐 PASO 1: Verificando autenticación...${NC}"
ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || echo "")

if [ -z "$ACCOUNT" ]; then
    echo -e "${RED}❌ No hay cuenta activa en gcloud${NC}"
    echo ""
    echo -e "${YELLOW}Por favor auténticate primero:${NC}"
    echo "  gcloud auth login"
    echo ""
    echo -e "${YELLOW}O si ya tienes cuentas, activa una:${NC}"
    echo "  gcloud auth list"
    echo "  gcloud config set account TU_EMAIL"
    exit 1
else
    echo -e "${GREEN}✅ Cuenta activa: $ACCOUNT${NC}"
fi

echo ""
echo -e "${YELLOW}📋 PASO 2: Listando todos tus proyectos...${NC}"
PROJECTS=$(gcloud projects list --format="value(projectId)" 2>/dev/null || echo "")

if [ -z "$PROJECTS" ]; then
    echo -e "${RED}❌ No se pudieron listar proyectos${NC}"
    exit 1
fi

echo -e "${GREEN}Proyectos encontrados:${NC}"
gcloud projects list --format="table(projectId,name,projectNumber)"

echo ""
echo -e "${YELLOW}🔍 PASO 3: Buscando clusters GKE en TODOS los proyectos...${NC}"
echo ""

FOUND_CLUSTER=false

for PROJECT in $PROJECTS; do
    echo -e "${BLUE}Buscando en proyecto: $PROJECT${NC}"
    
    # Temporalmente cambiar al proyecto para buscar clusters
    gcloud config set project $PROJECT --quiet 2>/dev/null
    
    CLUSTERS=$(gcloud container clusters list --format="value(name,location,status,currentNodeCount)" 2>/dev/null || echo "")
    
    if [ -n "$CLUSTERS" ]; then
        FOUND_CLUSTER=true
        echo -e "${GREEN}✅ ¡CLUSTERS ENCONTRADOS!${NC}"
        echo ""
        gcloud container clusters list --format="table(name,location,status,currentNodeCount)"
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}📌 PROYECTO CORRECTO: $PROJECT${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        # Obtener detalles del primer cluster
        CLUSTER_NAME=$(echo "$CLUSTERS" | head -n1 | awk '{print $1}')
        CLUSTER_ZONE=$(echo "$CLUSTERS" | head -n1 | awk '{print $2}')
        
        echo -e "${YELLOW}💡 Actualiza tus scripts con esta configuración:${NC}"
        echo ""
        echo "PROJECT_ID=\"$PROJECT\""
        echo "CLUSTER_NAME=\"$CLUSTER_NAME\""
        echo "ZONE=\"$CLUSTER_ZONE\""
        echo ""
    else
        echo "  ℹ️  No hay clusters en este proyecto"
    fi
    echo ""
done

if [ "$FOUND_CLUSTER" = false ]; then
    echo -e "${RED}❌ No se encontraron clusters GKE en ningún proyecto${NC}"
    echo ""
    echo -e "${YELLOW}Posibles razones:${NC}"
    echo "  1. El cluster fue eliminado"
    echo "  2. No tienes permisos para ver clusters"
    echo "  3. El cluster está en otro proyecto al que no tienes acceso"
    exit 1
fi

echo ""
echo -e "${YELLOW}📊 PASO 4: Verificando VMs de Compute Engine...${NC}"
echo ""

for PROJECT in $PROJECTS; do
    gcloud config set project $PROJECT --quiet 2>/dev/null
    
    VMS=$(gcloud compute instances list --format="value(name)" 2>/dev/null || echo "")
    
    if [ -n "$VMS" ]; then
        echo -e "${BLUE}Proyecto: $PROJECT${NC}"
        gcloud compute instances list --format="table(name,zone,machineType,status,internalIP)"
        echo ""
    fi
done

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ DIAGNÓSTICO COMPLETADO                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}🔧 Ahora actualiza la configuración en:${NC}"
echo "  - scripts/gcp-shutdown-all.sh"
echo "  - scripts/gcp-startup-all.sh"
echo ""
echo -e "${YELLOW}Con los valores de PROJECT_ID, CLUSTER_NAME y ZONE mostrados arriba${NC}"
echo ""
