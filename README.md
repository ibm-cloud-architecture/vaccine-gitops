# Gitops for vaccine solution

This repository includes the gitops for the vaccine solution deployment and uses [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/) to define the Kubernetes resources needed to run the different use cases.

The tree has the following structure, with `infrastructure` to defile kafka and postgres, `apps` to define application environment like secrets and configmaps, and the different components depending of the use cases to demonstrate.

```
├── apps
│   └── order-mgt
│       ├── base
│       │   ├── kustomization.yaml
│       │   ├── order-mgt-configmap.yaml
│       │   ├── order-mgt-deployconfig.yaml
│       │   ├── voro-configmap.yaml
│       │   └── voro-deployment.yaml
│       ├── kustomization.yaml
│       └── overlays
│           └── kustomization.yaml
├── environments
│   ├── dev
│   │   └── infrastructure
│   │       ├── kafka
│   │       │   ├── kafka-cluster.yaml
│   │       │   ├── kafka-topics.yaml
│   │       │   └── kafka-users.yaml
│   │       ├── kustomization.yaml
│   │       ├── namespace.yaml
│   │       ├── postgres
│   │       │   ├── base
│   │       │   │   ├── config
│   │       │   │   │   ├── kustomization.yaml
│   │       │   │   │   ├── statefulset.yaml
│   │       │   │   │   ├── svc-headless.yaml
│   │       │   │   │   └── svc.yaml
│   │       │   │   └── kustomization.yaml
│   │       │   ├── kustomization.yaml
│   │       │   └── overlays
│   │       │       ├── kustomization.yaml
│   │       │       └── service-account-patch.yaml
│   │       └── service-account.yaml
│   └── event-streams
│       └── infrastructure
│           ├── eventstreams
│           │   ├── IBMCatalogSource.yaml
│           │   ├── es-topics.yaml
│           │   ├── es-user.yaml
│           │   ├── eventstreams-minimal-prod.yaml
│           │   ├── eventstreams-prod-3-brokers.yaml
│           │   ├── kafka-configmap.yaml
│           │   ├── kustomization.yaml
│           │   └── namespace.yaml
│           ├── kustomization.yaml
│           ├── namespace.yaml
│           ├── postgres
│           │   ├── base
│           │   │   ├── kustomization.yaml
│           │   │   ├── statefulset.yaml
│           │   │   ├── svc-headless.yaml
│           │   │   └── svc.yaml
│           │   ├── kustomization.yaml
│           │   └── overlays
│           │       ├── kustomization.yaml
│           │       └── service-account-patch.yaml
│           └── service-account.yaml
```

In an attempt to create a CI process that minimizes the amount of infrastructure overhead, our CI process utilizes [GitHub Actions](https://github.com/features/actions) for automated docker image builds. 

Upon a code push to the `main` branch of a given repository, GitHub Actions will perform a docker build on the source code, create a new tag for the commit, tag the repository, tag the docker image, and push to the `ibmcase` Docker Hub organization.

### Development environment (`dev`)

This environment is deployable to any Kubernetes or OpenShift cluster and provides its own dedicated backing services.

Prerequisites:

- Strimzi operator must be installed, and configured to watch all namespaces.
- You are logged intp the OpenShift Cluster with `oc login...`

## Defining Kafka cluster, service account...

* One-time setup to create namespace, Kafka cluster and other entities:

```shell
oc apply -k environments/dev/infrastructure/
# Verify the two pods are running
oc get pods
# NAME                          READY   STATUS    RESTARTS   AGE
# vaccine-kafka-entity-operator-6c48b45c4b-pt7lw   3/3     Running   0          4m39s
# vaccine-kafka-kafka-0                            1/1     Running   0          5m12s
# vaccine-kafka-kafka-1                            1/1     Running   0          5m12s
# vaccine-kafka-kafka-2                            1/1     Running   0          5m11s
# vaccine-kafka-kafka-exporter-6c7d77d698-28697    1/1     Running   0          4m6s
# vaccine-kafka-zookeeper-0                        1/1     Running   0          5m51s
# vaccine-kafka-zookeeper-1                        1/1     Running   0          5m51s
# vaccine-kafka-zookeeper-2                        1/1     Running   0          5m51s
```

* The following command is required only if targeting an OpenShift cluster

```shell
oc adm policy add-scc-to-user anyuid -z vaccine-runtime -n vaccine-solution
```

* Verify the user created

```shell
oc get kafkausers
```

* Verify the topics created

```shell
oc get kafkatopics
#
# NAME                     CLUSTER         PARTITIONS   REPLICATION FACTOR   READY
# reefer.telemetries       vaccine-kafka   3            3                    True
# test                     vaccine-kafka   1            1                    True
# vaccine.inventory        vaccine-kafka   1            1                    True
# vaccine.reefer           vaccine-kafka   1            1                    True
# vaccine.shipment.plans   vaccine-kafka   1            3                    True
# vaccine.transportation   vaccine-kafka   1            1                    True
```

## Deploy postgresql

```shell
oc apply -k environments/dev/infrastructure/postgres
```


## Defining environment

The env folder includes setting up postgres credentials, Kafka topic names as config maps and service account. Normally deploying the `dev` environments will configure everything, but in case of we want to go step by step the following command will define the environment variables. Also it is important to modify the namespace if you do not use vaccine-solution as namespace.

```shell
 oc apply -k dev/env
```

## Deploying Vaccine cold chain monitoring components

## Deploying order management components

```shell
oc apply -k environments/dev/apps/order-mgt
```

This should deploy the optimization and order mgt.

```shell
oc get pods
# 
```

## Delete deployment

```shell
oc delete -k environments/dev
```