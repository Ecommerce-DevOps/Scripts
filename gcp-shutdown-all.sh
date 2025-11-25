#!/bin/bash

###############################################################################
# GCP SHUTDOWN SCRIPT - Apagar TODO para evitar gastos
###############################################################################
# Este script apaga TODOS los recursos de GCP para evitar costos innecesarios
# Uso: ./scripts/gcp-shutdown-all.sh
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
ZONE="us-central1-a"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     GCP SHUTDOWN - Apagando TODOS los recursos        ║${NC}"
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
echo -e "${RED}⚠️  ADVERTENCIA: Este script va a APAGAR TODOS los recursos:${NC}"
echo -e "${RED}   • Todos los pods en TODOS los namespaces${NC}"
echo -e "${RED}   • Todos los deployments y services${NC}"
echo -e "${RED}   • El cluster GKE completo${NC}"
echo -e "${RED}   • Todas las VMs de Compute Engine${NC}"
echo ""
read -p "¿Estás SEGURO que deseas continuar? (escribe 'SI' para confirmar): " CONFIRM

if [ "$CONFIRM" != "SI" ]; then
    echo -e "${GREEN}✅ Operación cancelada. No se apagó nada.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🔌 PASO 1: Escalando todos los deployments a 0 replicas${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Obtener credenciales del cluster
echo "Obteniendo credenciales del cluster..."
gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID 2>/dev/null || true

# Escalar todos los deployments en todos los namespaces a 0
NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

if [ -n "$NAMESPACES" ]; then
    for ns in $NAMESPACES; do
        echo -e "${YELLOW}📦 Namespace: $ns${NC}"
        
        # Obtener todos los deployments en este namespace
        DEPLOYMENTS=$(kubectl get deployments -n $ns -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
        
        if [ -n "$DEPLOYMENTS" ]; then
            for deploy in $DEPLOYMENTS; do
                echo "  ⬇️  Escalando deployment $deploy a 0 replicas..."
                kubectl scale deployment $deploy --replicas=0 -n $ns 2>/dev/null || true
            done
        else
            echo "  ℹ️  No hay deployments en este namespace"
        fi
        
        # Obtener todos los statefulsets
        STATEFULSETS=$(kubectl get statefulsets -n $ns -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
        
        if [ -n "$STATEFULSETS" ]; then
            for sts in $STATEFULSETS; do
                echo "  ⬇️  Escalando statefulset $sts a 0 replicas..."
                kubectl scale statefulset $sts --replicas=0 -n $ns 2>/dev/null || true
            done
        fi
    done
    
    echo ""
    echo -e "${GREEN}✅ Esperando 30 segundos para que los pods se terminen...${NC}"
    sleep 30
else
    echo -e "${YELLOW}⚠️  No se pudo obtener la lista de namespaces (cluster puede estar apagado)${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🗑️  PASO 2: Eliminando pods que aún estén corriendo${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -n "$NAMESPACES" ]; then
    for ns in $NAMESPACES; do
        echo -e "${YELLOW}📦 Namespace: $ns${NC}"
        
        PODS=$(kubectl get pods -n $ns -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
        
        if [ -n "$PODS" ]; then
            echo "  🗑️  Eliminando pods en $ns..."
            kubectl delete pods --all -n $ns --force --grace-period=0 2>/dev/null || true
        else
            echo "  ℹ️  No hay pods corriendo en este namespace"
        fi
    done
else
    echo -e "${YELLOW}⚠️  Saltando eliminación de pods (cluster puede estar apagado)${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🛑 PASO 3: Suspendiendo (apagando) el cluster GKE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "Verificando si el cluster existe..."
CLUSTER_EXISTS=$(gcloud container clusters list --filter="name=$CLUSTER_NAME" --format="value(name)" 2>/dev/null || echo "")

if [ -n "$CLUSTER_EXISTS" ]; then
    echo -e "${YELLOW}🛑 Reduciendo el node pool a 0 nodos (SUSPENDER cluster)...${NC}"
    
    # Obtener el nombre del node pool
    NODE_POOL=$(gcloud container node-pools list --cluster=$CLUSTER_NAME --region=$REGION --format="value(name)" 2>/dev/null | head -n 1)
    
    if [ -n "$NODE_POOL" ]; then
        echo "Node pool encontrado: $NODE_POOL"
        echo "Escalando a 0 nodos..."
        gcloud container clusters resize $CLUSTER_NAME \
            --node-pool=$NODE_POOL \
            --num-nodes=0 \
            --region=$REGION \
            --quiet 2>/dev/null || true
        
        echo -e "${GREEN}✅ Cluster suspendido (0 nodos)${NC}"
    else
        echo -e "${YELLOW}⚠️  No se encontró node pool${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  El cluster no existe o ya está eliminado${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}💻 PASO 4: Deteniendo todas las VMs de Compute Engine${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

VMS=$(gcloud compute instances list --format="value(name,zone)" 2>/dev/null || echo "")

if [ -n "$VMS" ]; then
    echo "$VMS" | while read -r vm_name vm_zone; do
        if [ -n "$vm_name" ]; then
            echo "  🛑 Deteniendo VM: $vm_name (zona: $vm_zone)..."
            gcloud compute instances stop $vm_name --zone=$vm_zone --quiet 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}✅ Todas las VMs han sido detenidas${NC}"
else
    echo -e "${GREEN}ℹ️  No hay VMs corriendo${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📊 PASO 5: Resumen del estado actual${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${GREEN}🔍 Estado del Cluster GKE:${NC}"
gcloud container clusters list --format="table(name,location,status,currentNodeCount)" 2>/dev/null || echo "No hay clusters"

echo ""
echo -e "${GREEN}💻 Estado de las VMs:${NC}"
gcloud compute instances list --format="table(name,zone,status)" 2>/dev/null || echo "No hay VMs"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                ✅ SHUTDOWN COMPLETADO                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📉 Ahora tu proyecto NO debería generar costos significativos${NC}"
echo -e "${YELLOW}💡 Para volver a iniciar:${NC}"
echo -e "${YELLOW}   1. Cluster GKE: gcloud container clusters resize $CLUSTER_NAME --num-nodes=4 --region=$REGION${NC}"
echo -e "${YELLOW}   2. VMs: gcloud compute instances start <VM_NAME> --zone=<ZONE>${NC}"
echo ""
