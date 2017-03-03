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

desc "There are just node disks in gcloud"
run "gcloud compute disks list"

desc "There are no storage classes"
run "kubectl get storageclasses"

NS="--namespace=demos"

desc "There are no PVs or PVCs"
run "kubectl ${NS} get pv,pvc"

desc "Add a storage class"
run "cat $(relative storage_class.yaml)"
run "kubectl apply -f storage_class.yaml"
run "kubectl get storageclasses"

desc "Add a PVC"
run "cat $(relative pvc_dynamic.yaml)"
run "kubectl apply -f pvc_dynamic.yaml"

desc "Wait for the PVC to bind"
while [ "$(kubectl ${NS} get pvc mypvc -o yaml | grep phase | cut -d: -f2 | tr -d [:space:])" != "Bound" ]; do
  run "kubectl ${NS} get pvc"
done
run "gcloud compute disks list"

desc "Create a Pod"
run "cat $(relative pod.yaml)"
run "kubectl apply -f pod.yaml"

desc "Check that the pod is running"
while [ "$(kubectl ${NS} get pod sleepypod -o yaml | grep phase | cut -d: -f2 | tr -d [:space:])" != "Running" ]; do
  run "kubectl ${NS} get pod sleepypod"
done

desc "Delete the Pod in Kubernetes and wait..."
run "kubectl delete -f pod.yaml"
desc "Make sure pod is deleted"
while [ "$(kubectl ${NS} get pod sleepypod 2>/dev/null)" != "" ]; do
  run "kubectl ${NS} get pod sleepypod"
done

desc "The PVC exists, so the disk still exists"
run "gcloud compute disks list"

desc "Delete the PVC"
run "kubectl delete -f pvc_dynamic.yaml"

desc "Now that the PVC is deleted the disk should be as well"
run "gcloud compute disks list"

