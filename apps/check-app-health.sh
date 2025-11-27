#!/bin/bash

# check-app-health.sh
# Verifies the health of deployed applications

NAMESPACE="staging"

echo "🏥 Checking Application Health in namespace: $NAMESPACE"
echo "==================================================="

# 1. Check Pod Status
echo "--- Pod Status ---"
kubectl get pods -n $NAMESPACE -o wide
echo ""

# 2. Check Service Endpoints
echo "--- Service Endpoints ---"
kubectl get endpoints -n $NAMESPACE
echo ""

# 3. Check Logs for Errors (Last 50 lines for each app)
apps=("user-service" "product-service" "order-service" "payment-service" "shipping-service" "favourite-service" "proxy-client" "discovery" "zipkin")

echo "--- Recent Logs (Errors) ---"
for app in "${apps[@]}"; do
    echo "Checking logs for $app..."
    # Get pod name
    pod_name=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=$app -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        # Try finding by 'app' label if 'app.kubernetes.io/name' fails (common in some charts)
        pod_name=$(kubectl get pods -n $NAMESPACE -l app=$app -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
    fi

    if [ -n "$pod_name" ]; then
        echo "Found pod: $pod_name"
        kubectl logs $pod_name -n $NAMESPACE --tail=20 | grep -i "error\|exception\|fail" || echo "No recent errors found."
    else
        echo "⚠️ Pod for $app not found!"
    fi
    echo "-----------------------------------"
done

echo "✅ Health check completed."
