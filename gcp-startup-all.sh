#!/bin/bash

###############################################################################
# GCP STARTUP SCRIPT - Encender TODO nuevamente
###############################################################################
# Este script enciende TODOS los recursos de GCP que fueron apagados
# Uso: ./scripts/gcp-startup-all.sh
###############################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración (ajusta estos valores según tu proyecto)
PROJECT_ID="ecommerce-backend-1760307199"
CLUSTER_NAME="ecommerce-devops-cluster"
REGION="us-central1"
ZONE="us-central1-c"
NUM_NODES=4  # Número de nodos para el cluster

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     GCP STARTUP - Encendiendo TODOS los recursos      ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo ""

# Verificar que estamos en el proyecto correcto
echo -e "${YELLOW}📋 Verificando proyecto GCP...${NC}"
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
echo "Proyecto actual: $CURRENT_PROJECT"

if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo -e "${YELLOW}⚠️  Cambiando a proyecto: $PROJECT_ID${NC}"
    gcloud config set project $PROJECT_ID
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}💻 PASO 1: Iniciando todas las VMs de Compute Engine${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

VMS=$(gcloud compute instances list --filter="status=TERMINATED" --format="value(name,zone)" 2>/dev/null || echo "")

if [ -n "$VMS" ]; then
    echo "$VMS" | while read -r vm_name vm_zone; do
        if [ -n "$vm_name" ]; then
            echo "  ▶️  Iniciando VM: $vm_name (zona: $vm_zone)..."
            gcloud compute instances start $vm_name --zone=$vm_zone --quiet 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}✅ Todas las VMs han sido iniciadas${NC}"
else
    echo -e "${GREEN}ℹ️  No hay VMs detenidas${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🚀 PASO 2: Iniciando el cluster GKE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "Verificando si el cluster existe..."
CLUSTER_EXISTS=$(gcloud container clusters list --filter="name=$CLUSTER_NAME" --format="value(name)" 2>/dev/null || echo "")

if [ -n "$CLUSTER_EXISTS" ]; then
    echo -e "${YELLOW}🚀 Escalando el cluster a $NUM_NODES nodos...${NC}"
    
    # Obtener el nombre del node pool
    NODE_POOL=$(gcloud container node-pools list --cluster=$CLUSTER_NAME --region=$REGION --format="value(name)" 2>/dev/null | head -n 1)
    
    if [ -n "$NODE_POOL" ]; then
        echo "Node pool encontrado: $NODE_POOL"
        echo "Escalando a $NUM_NODES nodos..."
        gcloud container clusters resize $CLUSTER_NAME \
            --node-pool=$NODE_POOL \
            --num-nodes=$NUM_NODES \
            --region=$REGION \
            --quiet
        
        echo -e "${GREEN}✅ Cluster iniciado con $NUM_NODES nodos${NC}"
        
        echo ""
        echo -e "${YELLOW}⏳ Esperando que los nodos estén listos (esto puede tomar 2-3 minutos)...${NC}"
        
        # Obtener credenciales
        gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID
        
        # Esperar a que los nodos estén Ready
        for i in {1..60}; do
            READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
            echo "  Nodos Ready: $READY_NODES/$NUM_NODES"
            
            if [ "$READY_NODES" -eq "$NUM_NODES" ]; then
                echo -e "${GREEN}✅ Todos los nodos están Ready!${NC}"
                break
            fi
            
            if [ $i -eq 60 ]; then
                echo -e "${YELLOW}⚠️  Timeout esperando nodos. Verifica manualmente.${NC}"
                break
            fi
            
            sleep 5
        done
    else
        echo -e "${YELLOW}⚠️  No se encontró node pool${NC}"
    fi
else
    echo -e "${RED}❌ El cluster no existe${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📦 PASO 3: Restaurando deployments${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${YELLOW}ℹ️  Para restaurar tus aplicaciones, tienes 2 opciones:${NC}"
echo ""
echo -e "${GREEN}Opción A - Desde manifests-gcp (manual):${NC}"
echo "  kubectl apply -f manifests-gcp/discovery/"
echo "  kubectl apply -f manifests-gcp/user-service/"
echo "  kubectl apply -f manifests-gcp/product-service/"
echo "  kubectl apply -f manifests-gcp/order-service/"
echo "  kubectl apply -f manifests-gcp/payment-service/"
echo "  kubectl apply -f manifests-gcp/shipping-service/"
echo "  kubectl apply -f manifests-gcp/favourite-service/"
echo ""
echo -e "${GREEN}Opción B - Disparar pipeline de Jenkins:${NC}"
echo "  Ejecuta el job: user-service-stage-pipeline"
echo ""

read -p "¿Deseas que el script aplique los manifests automáticamente? (s/n): " APPLY_MANIFESTS

if [ "$APPLY_MANIFESTS" = "s" ] || [ "$APPLY_MANIFESTS" = "S" ]; then
    echo ""
    echo -e "${YELLOW}📦 Aplicando manifests...${NC}"
    
    MANIFEST_DIRS=(
        "manifests-gcp/discovery"
        "manifests-gcp/user-service"
        "manifests-gcp/product-service"
        "manifests-gcp/order-service"
        "manifests-gcp/payment-service"
        "manifests-gcp/shipping-service"
        "manifests-gcp/favourite-service"
        "manifests-gcp/zipkin"
    )
    
    for dir in "${MANIFEST_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "  📁 Aplicando $dir..."
            kubectl apply -f "$dir/" 2>/dev/null || true
        fi
    done
    
    echo -e "${GREEN}✅ Manifests aplicados${NC}"
    
    echo ""
    echo -e "${YELLOW}⏳ Esperando que los pods estén corriendo...${NC}"
    sleep 30
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📊 PASO 4: Resumen del estado actual${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${GREEN}🔍 Estado del Cluster GKE:${NC}"
gcloud container clusters list --format="table(name,location,status,currentNodeCount)"

echo ""
echo -e "${GREEN}💻 Estado de las VMs:${NC}"
gcloud compute instances list --format="table(name,zone,status)" 2>/dev/null || echo "No hay VMs"

echo ""
echo -e "${GREEN}📦 Estado de los Pods:${NC}"
kubectl get pods --all-namespaces 2>/dev/null || echo "No se pudo obtener pods"

echo ""
echo -e "${GREEN}🌐 Services y IPs:${NC}"
kubectl get services --all-namespaces -o wide 2>/dev/null || echo "No se pudo obtener services"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                ✅ STARTUP COMPLETADO                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}🚀 Tu infraestructura está lista!${NC}"
echo ""
