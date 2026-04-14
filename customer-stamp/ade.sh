#!/bin/bash 

# Copyright (C) Microsoft Corporation. 

# Exit immediately if a command fails
set -e

# Fail if an unset variable is used
set -u

#declare command variables & functions
command=""
command_output=""
command_status=0

function clear_command_variables() {
    command=""
    command_output=""
    command_status=0
}

function execute_command_exit_on_failure() {
    local cmd=$1
    eval "$cmd"
    command_status=$?
    if [ $command_status -ne 0 ]; then
        echo "Error: Command failed with status $command_status"
        exit $command_status
    fi
}
#endregion declare command variables & functions

#region Declare Constants
DEV_CENTER_CATALOG_NAME="catalog"
ENVIRONMENT_DEFINITION_NAME="VirtualMachine" # Folder name where IaC template and environment file are hosted
ENVIRONMENT_TYPE="sandbox"
PROJECT_ADMIN_ID=$(az account get-access-token --query "accessToken" -o tsv | jq -R -r 'split(".") | .[1] | @base64d | fromjson | .oid')
echo "Object ID of the service principal or managed identity: $PROJECT_ADMIN_ID"
DEPLOYMENT_USER_OBJECT_ID="df0378a9-7039-4686-9591-9fcc42b9e34d"
PROJECT="adeproject"
description="This is my first project"
TARGET_SUBSCRIPTION_ID="250f62f2-46bc-4a3d-b362-d04ec87c9285"
MANAGED_ID="umidc"
RESOURCE_GROUP="rg-jmpcourt-dev01"
DEV_CENTER_NAME="dc-jmpcourt-dev01"
ENVIRONMENT_NAME="sandbox"
KEY_VAULT_NAME="akv-ade-ip"
#endregion Declare Constants

#region Install Azure Dev Center extension
echo "Installing the Azure Dev Center extension"
clear_command_variables
command="az extension add --name devcenter --upgrade"
execute_command_exit_on_failure "$command"
echo "Extension installation complete!"
#endregion Install Azure Dev Center extension

#region Get Role Id for the Subscription Owner
echo "Getting Role Id for the Subscription Owner"
clear_command_variables
command="az role definition list -n \"Owner\" --scope \"/subscriptions/$TARGET_SUBSCRIPTION_ID\" --query [].name -o tsv"
owner_role_id=""
execute_command_exit_on_failure "$command"
owner_role_id=$(eval "$command")
echo "Got Subscription Owner Role ID: $owner_role_id"
#endregion Get Role Id for the Subscription Owner

#region Get Dev Center ID
echo "Getting Azure Dev Center Resource ID"
clear_command_variables
command="az devcenter admin devcenter show \
  --name \"$DEV_CENTER_NAME\" \
  --resource-group \"$RESOURCE_GROUP\" \
  --query id -o tsv"
dev_center_id=""
execute_command_exit_on_failure "$command"
dev_center_id=$(eval "$command")
echo "Got Azure Dev Center Resource ID: $dev_center_id"
#endregion Get Dev Center ID

#region Get Managed Identity ID, Object ID
echo "Getting Managed Identity Resource ID"
clear_command_variables
command="az identity show --name \"$MANAGED_ID\" --resource-group \"$RESOURCE_GROUP\" --query id -o tsv"
managed_identity_id=""
execute_command_exit_on_failure "$command"
managed_identity_id=$(eval "$command")
echo "Got Managed Identity Resource ID: $managed_identity_id"

echo "Getting Managed Identity Object ID"
clear_command_variables
command="az resource show --ids \"$managed_identity_id\" --query properties.principalId -o tsv"
managed_identity_object_id=""
execute_command_exit_on_failure "$command"
managed_identity_object_id=$(eval "$command")
echo "Got Managed Identity Object ID: $managed_identity_object_id"
#endregion Get Managed Identity ID, Object ID

#region Create Project in Dev Center
echo "Creating Project in Azure Dev Center"
clear_command_variables
command="az devcenter admin project create \
  --name \"$PROJECT\" \
  --resource-group \"$RESOURCE_GROUP\" \
  --description \"$description\" \
  --dev-center-id \"$dev_center_id\""
execute_command_exit_on_failure "$command"
echo "Project created successfully!"
#endregion Create Project in Dev Center

#region Assign Roles to Managed Identity
echo "Assigning Contributor role to the Managed Identity Object ID on the subscription"
clear_command_variables
command="az role assignment create --role \"Contributor\" --assignee-object-id \"$managed_identity_object_id\" --scope \"/subscriptions/$TARGET_SUBSCRIPTION_ID\""
execute_command_exit_on_failure "$command"
echo "Assigned Contributor role to the Managed Identity Object ID on the subscription"

echo "Assigning User Access Administrator role to the Managed Identity Object ID on the subscription"
clear_command_variables
command="az role assignment create --role \"User Access Administrator\" --assignee-object-id \"$managed_identity_object_id\" --scope \"/subscriptions/$TARGET_SUBSCRIPTION_ID\""
execute_command_exit_on_failure "$command"
echo "Assigned User Access Administrator role to the Managed Identity Object ID on the subscription"
#endregion Assign Roles to Managed Identity

#region Create Environment Type for the Project
echo "Creating Project Environment Type"
clear_command_variables
command="az devcenter admin project-environment-type create \
  --name \"$ENVIRONMENT_TYPE\" \
  --project \"$PROJECT\" \
  --resource-group \"$RESOURCE_GROUP\" \
  --identity-type \"SystemAssigned\" \
  --roles \"{\\\"$owner_role_id\\\":{}}\" \
  --deployment-target-id \"/subscriptions/$TARGET_SUBSCRIPTION_ID\" \
  --status Enabled \
  --query 'identity.principalId' \
  --output tsv"
project_environment_type_object_id=""
execute_command_exit_on_failure "$command"
project_environment_type_object_id=$(eval "$command")
echo "Created Project Environment Type with Object ID: $project_environment_type_object_id"

echo "Assigning Contributor role to Project Environment Type identity"
for i in {1..10}
do
  command="az role assignment create \
    --assignee-object-id \"$project_environment_type_object_id\" \
    --assignee-principal-type ServicePrincipal \
    --role \"Contributor\" \
    --scope \"/subscriptions/$TARGET_SUBSCRIPTION_ID\""
  if eval "$command"; then
    echo "Role assignment succeeded"
    break
  fi
  echo "Waiting for identity propagation... retry $i"
  sleep 15
done

echo "Assigning Contributor role to the Project Environment Type Object ID on the subscription"
clear_command_variables
command="az role assignment create --role \"Contributor\" --assignee-object-id $project_environment_type_object_id --scope \"/subscriptions/$TARGET_SUBSCRIPTION_ID\""
execute_command_exit_on_failure "$command"
echo "Assigned Contributor role to the Project Environment Type Object ID"
#endregion Create Environment Type for the Project

#region Assign Key Vault Secrets Officer Role
echo "Assigning Key Vault Secrets Officer role to the Project Environment Type Object ID on the keyvault"
clear_command_variables
command="az role assignment create --role \"Key Vault Secrets Officer\" --assignee-object-id $project_environment_type_object_id --scope \"/subscriptions/$TARGET_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEY_VAULT_NAME\""
execute_command_exit_on_failure "$command"
echo "Assigned Key Vault Secrets Officer role to the Project Environment Type Object ID on the keyvault"
#endregion Assign Key Vault Secrets Officer Role

#region Assign Dev Center Project Admin and Deployment Environments User Roles
echo "Assigning Dev Center Project Admin role to $PROJECT_ADMIN_ID"
clear_command_variables
command="az role assignment create --assignee \"$PROJECT_ADMIN_ID\" --role \"DevCenter Project Admin\" --scope \"/subscriptions/$TARGET_SUBSCRIPTION_ID\""
execute_command_exit_on_failure "$command"
echo "Assigned Dev Center Project Admin role to $PROJECT_ADMIN_ID"

echo "Assigning Deployment Environments User role"
clear_command_variables
command="az role assignment create \
  --assignee-object-id \"$DEPLOYMENT_USER_OBJECT_ID\" \
  --assignee-principal-type User \
  --role \"Deployment Environments User\" \
  --scope \"/subscriptions/$TARGET_SUBSCRIPTION_ID\""
execute_command_exit_on_failure "$command"
echo "Assigned Deployment Environments User role to object ID: $DEPLOYMENT_USER_OBJECT_ID"
#endregion Assign Dev Center Project Admin and Deployment Environments User Roles

#region Create Dev Environment
echo "Creating Dev Environment"
clear_command_variables
command="az devcenter dev environment create --environment-name \"$ENVIRONMENT_NAME\" --environment-type \"$ENVIRONMENT_TYPE\" --dev-center-name \"$DEV_CENTER_NAME\" --project-name \"$PROJECT\" --catalog-name \"$DEV_CENTER_CATALOG_NAME\" --environment-definition-name \"$ENVIRONMENT_DEFINITION_NAME\""
execute_command_exit_on_failure "$command"
echo "Created Dev Environment: $ENVIRONMENT_NAME"
#endregion Create Dev Environment
