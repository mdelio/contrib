#!/bin/bash
# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

. $(dirname ${BASH_SOURCE})/../util.sh

desc "Check: there are just node disks in gcloud"
run "gcloud compute disks list"

desc "Check: there are no storage classes"
run "kubectl get storageclasses"

NS="--namespace=demos"

desc "Check: there are no PVs or PVCs"
run "kubectl ${NS} get pv,pvc"

desc "STEP 1: add a storage class"
run "cat $(relative storage_class.yaml)"
run "kubectl apply -f storage_class.yaml"
run "kubectl get storageclasses"

desc "STEP 2: add a PVC"
run "cat $(relative pvc_dynamic.yaml)"
run "kubectl apply -f pvc_dynamic.yaml"

desc "Check: wait for the PVC to bind"
while [ "$(kubectl ${NS} get pvc mypvc -o yaml | grep phase | cut -d: -f2 | tr -d [:space:])" != "Bound" ]; do
  run "kubectl ${NS} get pvc"
done
run "gcloud compute disks list"

desc "STEP 3: use the PVC in a Pod"
run "cat $(relative pod.yaml)"
run "kubectl apply -f pod.yaml"

desc "Check: that the pod is running"
while [ "$(kubectl ${NS} get pod sleepypod -o yaml | grep phase | cut -d: -f2 | tr -d [:space:])" != "Running" ]; do
  run "kubectl ${NS} get pod sleepypod"
done

desc "SUCCESS! Now delete/destroy everything..."
run "kubectl delete -f pod.yaml"
desc "Make sure pod is deleted"
while [ "$(kubectl ${NS} get pod sleepypod 2>/dev/null)" != "" ]; do
  run "kubectl ${NS} get pod sleepypod"
done

desc "Note: because the PVC still, the disk does too"
run "gcloud compute disks list"

desc "Delete the PVC"
run "kubectl delete -f pvc_dynamic.yaml"

desc "Check: the PVC is deleted the disk is as well"
run "gcloud compute disks list"

