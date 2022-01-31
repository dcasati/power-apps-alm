#!/usr/bin/env bash

AAD_SP_NAME="myALMdemo"
PAC_AUTH_NAME="alm-demo-cli"
POWER_APPS_URL="https://orgXXXXX.crm.dynamics.com"
POWER_APPS_AZURE_USER="admin@iXYZ.onmicrosoft.com"

az ad  app credential reset     	\
    --id $(jq -r .appId pp_alm.rc) 	\
    --credential-description "GBB ALM Demo" > pp_alm-client-secret.rc

pac auth create                            	\
    --url ${POWER_APPS_URL}                	\
    --name ${PAC_AUTH_NAME}                	\
    --applicationId $(jq -r .appId pp_alm.rc)  	\
    --tenant $(jq -r .tenant pp_alm.rc)        	\
    --clientSecret $(jq -r .password pp_alm-client-secret.rc)
