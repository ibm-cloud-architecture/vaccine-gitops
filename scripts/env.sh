##################
### PARAMETERS ###
##################

# Username and Password for an OpenShift user with cluster-admin privileges.
# cluster-admin privileges are required as this script deploys operators to
# watch all namespaces.
OCP_ADMIN_USER=${OCP_ADMIN_USER:=admin}
OCP_ADMIN_PASSWORD=${OCP_ADMIN_PASSWORD:=admin}
KAFKA_CLUSTER_NAME=eda-dev
YOUR_SUFFIX=jb
YOUR_PROJECT_NAME=vaccine-solution
YOUR_TELEMETRIES_TOPIC=reefer.telemetries
YOUR_REEFER_TOPIC=vaccine.reefers
# Cloud pak for data user - keep it empty so the code will not use anomaly detection WML
YOUR_CP4D_USER=
YOUR_CP4D_API_KEY=
# URL to authenticate a user to get a JWT token
YOUR_CP4D_AUTH_URL=
ANOMALY_DETECTION_URL=