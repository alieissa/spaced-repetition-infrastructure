#! /bin/bash
cluster=sp 
capacityprovider=sp-api
services=$(aws ecs list-services --cluster ${cluster} | jq --raw-output '.serviceArns[]')
aws ecs describe-services \
    --cluster ${cluster} \
    --services ${services} \
    | jq -r --arg capacityprovider "${capacityprovider}" \
    '.services[] | select(.capacityProviderStrategy[]?.capacityProvider == $capacityprovider) | .serviceName'
