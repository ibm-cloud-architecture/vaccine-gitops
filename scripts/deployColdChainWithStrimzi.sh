#!/bin/bash
scriptDir=$(dirname $0)

##################
### PARAMETERS ###
##################

source ${scriptDir}/env-strimzi.sh

###################################
### DO NOT EDIT BELOW THIS LINE ###
###################################
### EDIT AT YOUR OWN RISK      ####
###################################
ENVPATH=environments/strimzi
SA_NAME=vaccine-runtime
SCRAM_USER=scram-user
TLS_USER=tls-user

############
### MAIN ###
############
source ${scriptDir}/login.sh
### Login
# Make sure we don't have more than 1 argument
if [[ $# -gt 1 ]];then
 echo "Usage: sh  `basename "$0"` [--skip-login]"
 exit 1
fi

validateLogin $1

source ${scriptDir}/defineProject.sh

createProjectAndServiceAccount $YOUR_PROJECT_NAME $SA_NAME
kafkaRunning=$(oc get pods | grep kafka 2> /dev/null)
if [[ -z $kafkaRunning ]]
then
  echo "Create Kafka Cluster with Strimzi"
  ${scriptDir}/deployStrimzi.sh --skip-login
  echo "Waiting for Kafka cluster to be available..."
  counter=0
  until [[ ($(oc get pods -n ${KAFKA_NS} | grep kafka 2> /dev/null)) || ( ${counter} == 60 ) ]]
  do
    echo "Waiting for Kafka cluster to be available..."
    ((counter++))
    sleep 5
  done
fi

echo "#####################################################"
echo "Create secrets for topic name and bootstrap server URL"
echo "#####################################################"

KAFKA_BOOTSTRAP=$(oc get route -n ${KAFKA_NS} ${KAFKA_CLUSTER_NAME}-kafka-bootstrap -o jsonpath="{.status.ingress[0].host}:443")
if [[ -z $(oc get secret reefer-simul-secret) ]]
then
    echo "reefer-simul-secret  not found -> create it"
    oc create secret generic reefer-simul-secret \
    --from-literal=KAFKA_BOOTSTRAP_SERVERS=$EXTERNAL_KAFKA_BOOTSTRAP_SERVERS \
    --from-literal=KAFKA_MAIN_TOPIC=$YOUR_TELEMETRIES_TOPIC \
    --from-literal=FREEZER_MGR_URL=$FREEZER_MGR_URL
fi
if [[ -z $(oc get secret reefer-monitoring-agent-secret 2> /dev/null) ]]
then
    echo "reefer-monitoring-agent-secret  not found -> create it"
    oc create secret generic reefer-monitoring-agent-secret \
    --from-literal=KAFKA_BOOTSTRAP_SERVERS=$INTERNAL_KAFKA_BOOTSTRAP_SERVERS \
    --from-literal=CP4D_USER=$YOUR_CP4D_USER \
    --from-literal=CP4D_API_KEY=$YOUR_CP4D_API_KEY \
    --from-literal=CP4D_AUTH_URL=$YOUR_CP4D_AUTH_URL \
    --from-literal=ANOMALY_DETECTION_URL=$ANOMALY_DETECTION_URL
fi

if [[ -z $(oc get secret freezer-mgr-secret 2> /dev/null) ]]
then
    echo "freezer-mgr-secret not found -> create it"
    
    oc create secret generic freezer-mgr-secret \
    --from-literal=KAFKA_BOOTSTRAP_SERVERS=$INTERNAL_KAFKA_BOOTSTRAP_SERVERS \
    --from-literal=REEFER_TOPIC=$YOUR_REEFER_TOPIC \
    --from-literal=ALERTS_TOPIC=$YOUR_ALERT_TOPIC \
    --from-literal=KAFKA_USER=$TLS_USER \
    --from-literal=KAFKA_CA_CERT_NAME=kafka-cluster-ca-cert 
fi

if [[ -z $(oc get secret kafka-cluster-ca-cert 2> /dev/null) ]]
then
    echo "kafka-cluster-ca-cert not found copy from ${KAFKA_CLUSTER_NAME}-cluster-ca-cert"
    oc get secret ${KAFKA_CLUSTER_NAME}-cluster-ca-cert -n ${KAFKA_NS} -o json | jq -r '.metadata.name="kafka-cluster-ca-cert"' |jq -r '.metadata.namespace="'${PROJECT_NAME}'"' | oc apply -f -
fi


echo "#####################################################"
echo "DEPLOY APPLICATION MICROSERVICES"
echo "#####################################################"
oc apply -k apps/cold-chain-use-case

### GET ROUTE FOR USER INTERFACE MICROSERVICE
echo "User Interface Microservice is available via http://$(oc get route vaccine-reefer-simulator -o jsonpath='{.status.ingress[0].host}')"


echo "#############"
echo "# Done ! "
echo "#############"
oc get pods 
echo "#############"
echo "When you are done with the lab do: ... ./scripts/deleteColdChain.sh" 
