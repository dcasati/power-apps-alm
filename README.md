# Power Apps ALM Demo

On this demo you will find the necessary steps on how to setup ALM for Power Apps using Github as the Version Control System.

TL;DR - clone this repo. Run the `run.sh` command to get your environment setup. Follow along for more details.

Fill in the following details:

```bash
AAD_SP_NAME="myALMdemo"
PAC_AUTH_NAME="alm-demo-cli"
POWER_APPS_URL="https://orgXXXXXX.crm.dynamics.com"
POWER_APPS_AZURE_USER="admin@XYZ.onmicrosoft.com"
```

Create a Service Principal on Azure using your current user. For this example, we will be using a user without an Azure subscription

```bash
az login --allow-no-subscription -u ${POWER_APPS_AZURE_USER}
az ad sp create-for-rbac --name ${AAD_SP_NAME} --skip-assignment > pp_alm.rc
```

We will use a Secret to authenticate the Service Pricipal. For that reason, we will reset it's credential (to be used later)

```bash
az ad  app credential reset         \
    --id $(jq -r .appId pp_alm.rc)  \
    --credential-description "GBB ALM Demo" > pp_alm-client-secret.rc
```

Navigate to the `Power Platform admin center` at `https://admin.powerplatform.microsoft.com`. On this step we will connect the new Service Principal user (created above) with our Power Platform Environment. Select an environment then click on `S2S Apps`

![powerplatform-alm-1](https://user-images.githubusercontent.com/3240777/151890253-cf8d68c8-858f-4f90-a0d8-2563adddc2ca.png)

Create a new user by clicking on "Setup app user"

![powerplatform-alm-2](https://user-images.githubusercontent.com/3240777/151890339-6c9a8ae9-261c-45a2-8044-90e0bf77ecbc.png)

Select the Service Principal user previously created here.

![powerplatform-alm-3](https://user-images.githubusercontent.com/3240777/151890413-865cf7c8-e1a2-4918-88eb-c90c2d06ec86.png)

Under `Security roles`, click on the pencil icon and select `System Administrator` from the dropbown options

![powerplatform-alm-4](https://user-images.githubusercontent.com/3240777/151890510-2c190b10-880d-4638-89fa-299647396516.png)

![powerplatform-alm-5](https://user-images.githubusercontent.com/3240777/151890525-ef90e87d-57ac-4762-bc44-a985d6eca4f4.png)

Create an authentication for `pac`. 
```bash
 pac auth create                                \
    --url ${POWER_APPS_URL}                     \
    --name ${PAC_AUTH_NAME}                     \
    --applicationId $(jq -r .appId pp_alm.rc)   \
    --tenant $(jq -r .tenant pp_alm.rc)         \
    --clientSecret $(jq -r .password pp_alm-client-secret.rc)
```

You can check to see if you are authenticated by listing the current solutions in Power Apps
```bash
pac solution list
```

Export a solution. For this example we will be exporting the `CustomTranslator`
```bash
 pac solution export -p solution.zip -n CustomTranslator
 ```

Unpack the solution locally
 ```bash
pac solution unpack --zipfile solution.zip --folder publisher
 ```

 Import to the solution files into Github

 ```bash
 git add -a .
 git commit -m 'initial import'
 git push
 ```

Create Github secret

```bash
gh secret set -f - << EOF
URL=${POWER_APPS_URL}
TENANT_ID=$(jq -r .tenant pp_alm-client-secret.rc)
CLIENT_ID=$(jq -r .appId pp_alm-client-secret.rc)
CLIENT_SECRET=$(jq -r .password pp_alm-client-secret.rc)
EOF
```