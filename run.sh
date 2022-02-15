#!/usr/bin/env bash
set -eo pipefail

source deploy.rc 

__usage="
    -f  filename for the payload
    -x  action to be executed. 
Possible verbs are:
    install        deploy the ALM demo resources.
    delete         delete the ALM demo resources.
"
usage() {
    echo "usage: ${0##*/} [options]"
    echo "${__usage/[[:space:]]/}"
    exit 1
}

# a wrapper around the command to be executed
cmd() {
    echo "\$ ${@}"
    "$@"
}

# setup the Service Principal on Azure
do_azure_setup() {
    echo "Logging to Azure"
    cmd az login --allow-no-subscriptions \
	    --username ${POWER_APPS_AZURE_USER}

    echo "Creating a Service Principal"
    cmd az ad sp create-for-rbac --name ${AAD_SP_NAME} --skip-assignment > pp_alm.rc

    cmd az ad  app credential reset     \
        --id $(jq -r .appId pp_alm.rc) 	\
        --credential-description "GBB ALM Demo" > pp_alm-client-secret.rc
}

# setup pac auth
do_pac_setup() {
    cmd pac auth create                            	\
        --url ${POWER_APPS_URL}                	    \
        --name ${PAC_AUTH_NAME}                	    \
        --applicationId $(jq -r .appId pp_alm.rc)   \
        --tenant $(jq -r .tenant pp_alm.rc)        	\
        --clientSecret $(jq -r .password pp_alm-client-secret.rc)
}

# setup GitHub secrets to be used later with GitHub Actions
do_gh_setup() {
    gh secret set -f - << EOF
    URL=${POWER_APPS_URL}
    TENANT_ID=$(jq -r .tenant pp_alm-client-secret.rc)
    CLIENT_ID=$(jq -r .appId pp_alm-client-secret.rc)
    CLIENT_SECRET=$(jq -r .password pp_alm-client-secret.rc)
EOF
}

do_install(){
    do_azure_setup
    do_powerapps_setup
    do_pac_setup
    do_github_setup
}

do_delete() {
    echo "Deleting the Service Principal"
    CLIENT_ID=$(jq -r .appId pp_alm-client-secret.rc)
    az ad sp delete --id ${CLIENT_ID}
}

exec_case() {
    local _opt=$1
    
    case ${_opt} in
    install)    do_install;;
    delete)     do_delete;;
    setup-gh)   do_gh_setup;;
    *)          usage;;
    esac
    unset _opt
}

while getopts "f:o:x:" opt; do
    case $opt in
    f)  _FILENAME="${OPTARG}";;
    o)  _OUTPUT_TYPE="${OPTARG}";;
    x)  exec_flag=true
        EXEC_OPT="${OPTARG}"
        ;;
    *)  usage;;
    esac
done
shift $(( $OPTIND - 1 ))

if [ $OPTIND = 1 ]; then
    usage
    exit 0
fi

if [[ "${exec_flag}" == "true" ]]; then
    exec_case ${EXEC_OPT}
fi

exit 0