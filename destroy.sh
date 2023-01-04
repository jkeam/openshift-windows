#!/bin/bash

# Poll with a command waiting for a certain return code
#   arg1: delay seconds
#   arg2: return code as an int
#   arg3: command as a string
poll_for_return_code() {
  # until [ "$?" -eq $2 ]; do eval $3; sleep $1; done
  until [ "$?" -eq $2 ]
  do
    sleep $1
    eval $3
  done
}

# delete app
oc delete -f ./ocp/app.yaml
poll_for_return_code 5 1 "oc get project windoze -o name"

# delete operator
oc delete -f ./ocp/operator.yaml

# delete machineset
oc project openshift-machine-api
oc process -f ./ocp/machine-set-template.yaml -p INFRA_ID=$(oc get -o jsonpath='{.status.infrastructureName}{"\n"}' infrastructure cluster) -p ZONE=us-east-1a -p REGION=us-east-1 -p AMI=ami-0ec317eee5f7e45f0 | oc delete -f -
oc delete -f ./ocp/runtime-class.yaml
