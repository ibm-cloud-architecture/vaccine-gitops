oc delete -k apps/cold-chain-use-case
oc delete secret tls-user
oc delete secret scram-user
oc delete secret tls-user
oc delete sa service-account
oc delete sa reefer-monitoring-agent