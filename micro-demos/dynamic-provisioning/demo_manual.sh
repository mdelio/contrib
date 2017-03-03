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

NS="--namespace=demos"

desc "There are no PVs"
run "kubectl get pv"

desc "There are no PVCs"
run "kubectl ${NS} get pvc"

DISK="manual-disk-1"
desc "Create a new disk in Google Cloud"
run "gcloud compute disks create --size=200GB ${DISK}"

desc "Make sure ${DISK} exists!"
run "gcloud compute disks list"

desc "Add a PV to Kubernetes"
run "cat $(relative pv_manual.yaml)"
run "kubectl apply -f pv_manual.yaml"

desc "Make sure the PV exists"
run "kubectl get pv"

desc "Claim the PV in Kubernetes"
run "cat $(relative pvc_manual.yaml)"
run "kubectl apply -f pvc_manual.yaml"

desc "Check that the PV is bound to the PVC"
run "kubectl ${NS} get pv,pvc"

desc "Use the PVC in a Pod definition"
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

desc "Now delete the PVC and PV in Kubernetes"
run "kubectl delete -f pvc_manual.yaml"
run "kubectl delete -f pv_manual.yaml"
run "kubectl ${NS} get pvc,pv"

desc "...and delete the disk in GCP"
run "gcloud compute disks delete ${DISK}"
run "gcloud compute disks list"
