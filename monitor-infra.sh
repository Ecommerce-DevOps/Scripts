#!/bin/bash

# monitor-infra.sh
# Checks the health of the infrastructure

echo "Checking Infrastructure Health..."
echo "==============================="

# Check Nodes
echo "Nodes Status:"
kubectl get nodes
echo ""

# Check Pods in all namespaces
echo "Pods Status (All Namespaces):"
kubectl get pods --all-namespaces
echo ""

# Check Services
echo "Services Status:"
kubectl get svc --all-namespaces
echo ""

echo "Health check completed."
