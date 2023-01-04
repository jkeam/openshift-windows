#!/bin/bash

poll_for_operator_creation() {
  while true; do
    OUTPUT=$(oc get csv -n openshift-windows-machine-config-operator -o json | jq '[.items[0].status.phase][0]')
    if [[ "$OUTPUT" == "\"Succeeded\"" ]];
    then
      break
    else
      sleep 10
      OUTPUT=$(oc get csv -n openshift-windows-machine-config-operator -o json | jq '[.items[0].status.phase][0]')
    fi
  done
}

echo 'installing operator...'
oc create -f ./ocp/operator.yaml
poll_for_operator_creation

echo 'generating key...'
rm -rf ./windows-key*
ssh-keygen -t ed25519 -N '' -f ./windows-key
oc create secret generic cloud-private-key --from-file=private-key.pem=./windows-key -n openshift-windows-machine-config-operator

echo 'creating machineset and runtime class...'
oc project openshift-machine-api
oc process -f ./ocp/machine-set-template.yaml -p INFRA_ID=$(oc get -o jsonpath='{.status.infrastructureName}{"\n"}' infrastructure cluster) -p ZONE=us-east-1a -p REGION=us-east-1 -p AMI=ami-0ec317eee5f7e45f0 | oc create -f -
oc create -f ./ocp/runtime-class.yaml

echo 'deploying app...'
oc create -f ./ocp/app.yaml
oc project windoze
