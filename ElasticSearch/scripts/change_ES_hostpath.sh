#!/bin/bash
#
# Script to change storage on the ES cluster
# Default storage is PV, changing to hostPath volumes mounted on each infra node.
#
#set -x

# VARS
oc_bin=$(which oc)
# END OF VARS

function var_control() {
printf "\n*************************\n"
printf "Checking parameters...\n"
printf "*************************\n"
if [ $# -ne 3 ]; then
  printf "Error: missing parameters, required 3: user + password + ES path\n"
  usage
  exit 1
else
  printf "Great, detected 3 parameters!\n\n"
fi

}

function usage() {
printf "USAGE: ./$(basename $0) -u <OpenShift Username> -p <OpenShift password> -P <ES path>\n\n"
}

function login_OCP_cluster() {
printf "\n*************************\n"
printf "Log in OCP cluster...\n"
printf "*************************\n"
$oc_bin login -u $user -p $password
}

function get_dc_ES() {
dcs=$($oc_bin get dc -n openshift-logging -l component=es -o name)
}

function apply_changes_ES() {
# Cancel Rollout
printf "\n*********************************************\n"
printf "Cancelling previous DeploymentConfig rollout...\n"
printf "*********************************************\n"
for dc in $dcs
do
  $oc_bin rollout cancel $dc
done

# Add privileged scc to serviceaccount
printf "\n*********************************************\n"
printf "Adding privileged scc to ES serviceaccount...\n"
printf "*********************************************\n"
$oc_bin adm policy add-scc-to-user privileged system:serviceaccount:openshift-logging:aggregated-logging-elasticsearch

# Apply SecurityContext to each ES dc
printf "\n*********************************************************\n"
printf "Applying new privileged SecurityContext to every ES dc...\n"
printf "*********************************************************\n"
for dc in $dcs 
do     
  oc scale $dc --replicas=0     
  oc patch $dc -p '{"spec":{"template":{"spec":{"containers":[{"name":"elasticsearch","securityContext":{"privileged": true}}]}}}}'   
done

# Patch every ES dc to apply nodeSelector
printf "\n***********************************************************\n"
printf "Patching every ES DeploymentConfig to apply nodeSelector...\n"
printf "***********************************************************\n"
num=1
for dc in $dcs
do
  $oc_bin patch $dc -p '{"spec":{"template":{"spec":{"nodeSelector":{"logging-es-node":"'$num'"}}}}}}'
  let num=num+1
done

# Patch every ES dc to set hostPath storage type
printf "\n****************************************************\n"
printf "Patching every ES dc to set hostPath storage type...\n"
printf "****************************************************\n"
for dc in $dcs
do
  $oc_bin set volume $dc --add --overwrite --name=elasticsearch-storage --type=hostPath --path=$ES_path
  $oc_bin rollout latest $dc
  $oc_bin scale $dc --replicas=1
done
}

# MAIN
while getopts ":u:p:P:" args; do
  case "${args}" in
    u)
      user=${OPTARG}
      ;;
    p)
      password=${OPTARG}
      ;;
    P)
      ES_path=${OPTARG}
      ;;
    *)
      printf "Missing required parameters\n\n"
      usage
      exit 1
      ;;
  esac
done
  
var_control $user $password $ES_path
login_OCP_cluster
get_dc_ES
apply_changes_ES

