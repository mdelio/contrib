#!/bin/sh

kubectl delete -f pod.yaml
kubectl delete -f pvc_manual.yaml
kubectl delete -f pvc_dynamic.yaml

kubectl delete -f pv_manual.yaml

kubectl delete -f storage_class.yaml

gcloud compute disks delete manual-disk-1
