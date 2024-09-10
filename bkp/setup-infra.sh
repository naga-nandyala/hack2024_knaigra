#!/bin/bash
source .env

## Environment variables
base_name="$BASE_NAME"
location="$LOCATION"
adls_gen2_connection_id="$ALDS_GEN2_CONNECTION_ID"
subscription_id="$SUBSCRIPTION_ID"


# Variable set based on Terraform output
tf_storage_account_name=""
tf_storage_container_name=""

deploy_terraform_resources() {
    cd "$1" || exit

    user_principal_name=$(az ad signed-in-user show --query userPrincipalName -o tsv)

    terraform init
    terraform apply \
        -auto-approve \
        -var "subscription_id=$subscription_id" \
        -var "base_name=$base_name" \
        -var "location=$location" \
        -var "fabric_capacity_admin=$user_principal_name"

    tf_storage_container_name=$(terraform output --raw storage_container_name)    
}



echo "[I] ############ START ############"
echo "[I] ############ Deploying terraform resources ############"
deploy_terraform_resources "./terraform"
