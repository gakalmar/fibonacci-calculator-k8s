# Fibonacci-calculator
- A simple fibonacci sequence calculator application created to showcase complex application deployment with automated CI/CD integration:
    - `React` frontend
    - `Express` backend
    - Store data in `redis` and in `postgres` (intentional complexity for practice purposes!)
    - Use `nginx` to route incoming requests in development

# Start
- clone the repo:
    - `git clone https://github.com/gakalmar/fibonacci-calculator.git`
- 

# Deploying a multi-container app:
- Architecture:
    - Traffic comes into our Node using an `Ingress` (we will be setting this up all as a single node first!)
    - It redirects traffic to the Client and Server (API), which are set up as deployments, that use a `ClusterIP` service.
    - The Server/API is then connected to Redis and Postgres, both being separate deployments, also using a `ClusterIP` service.
    - The worker deployment is connected to the `ClusterIP` of Redis
    - A `PVC` (Persistent Volume Claim) is set up for the Postgres pod

- Steps:
    1. Create config files for each element/object we will be using:
        - Create main architecure first:
            - `client-deployment.yaml`
            - `client-cluster-ip-service.yaml`
            - `server-deployment.yaml` (we will have to add also the ENV variables for Redis and Postgres!)
            - `server-cluster-ip-service.yaml`
            - `worker-deployment.yaml` (we will have to add also the ENV variables for Redis and Postgres! But no service or port setup is needed, because we are only connecting FROM it, not TO it)
            - `redis-deployment.yaml`
            - `redis-cluster-ip-service.yaml`
            - `postgres-deployment.yaml`
            - `postgres-cluster-ip-service.yaml`

        - Create persistent volumes for databases: 
            - `database-persistent-volume-claim.yaml`
                - Update `postgres-deployment.yaml` file with:
                    - `template/spec` section with `volumes`
                    - `containers` section with `volumeMounts` (`subPath` is only required for postgres specifically!)

        - Config files can also be combined (eg. add the service and the deployment in a single file, that work together):
            - We just need to copy them one after the other in the file, and separate them with a `---` line
    
    2. Test the setup locally on minikube:
        - to apply a group of config files:
            - `kubectl apply -f k8s` (we refer to the folder, and everything inside it will be applied)

    3. Create a Github/Travis flow to build images and deploy
    4. Deploy the app to a cloud provider

- Kubernetes-object descriptions:
    - `ClusterIP` service:
        - services in general: objects that are used to create networking in a cluster
        - more restrictive than a `NodePort`
        - exposes pods to other objects **within the cluster** (no external access is allowed!)
        - only uses `port` and `targetPort` (because it's not reachable form outside)
            - `port` is through what other k8s objects reach the object (eg. deployment) the service is attached to
            - `targetPort` is the port the service is connected to (eg. the exposed port of the deployment)
        - specify `type` as `ClusterIP`
    
    - `Persistent Volume Claim` (`PVC`):
        - We use these when working with databases, so that a restarted pod will still have the same data that the previous one created (otherwise it would be deleted)
        - That's why we create a volume, that is independent from the container running inside the pod (it's basically a volume on a host machine)
        - We need to avoid creating multiple replicas of a database's container (we are only using `replicas: 1`!)
        - `Volume`:
            - In general (eg in Docker): 
                - a *mechanism* that allows a container to *access* a file system outside itself
            - Kubernetes `Volumes`: 
                - an `object` that allows a container to *store* data **at the pod level** 
                - The standard kubernetes `volume` will be created within the pod, next to the database (eg. Postgres) container, so it will survice a container-restart, but not a pod restart
            - In Kubernetes we also have `Persistent Volume` and `Persistent Volume Claim`:
                - The `PV` is created **outside** the pod, so if the pod crashes, the volume is still live
                - The `PVC` is basically a catalog of all the different volumes available, that you can get for your pod. These storage options need to be defined in the config file you create it with:
                    - Statically provisioned Persistent Volumes are the volumes that are pre-created
                    - Dynamically provisioned Persistent Volumes are the volumes that aren't pre-created, only created when you specifically ask for them
                - The `PVC` is what theb gets attached to the pod, in its configuration
                - `PVC` access modes:
                    - `ReadWriteOnce`: can be used by a single node
                    - `ReadOnlyMany`: Multiple nodes can read from this
                    - `ReadWriteMany`: Can be read and written to by many nodes
            - To find out more about what kinds of `PV`s Kubernetes can create locally, we use the following command:
                - `kubectl get storageclass` -> will list the available storage options
                    - `k8s.io/minikube-hostpath` is the default - this means "isolate a piece of my local drive for the usage of Kubernetes"
                    - more options are avalilable depending on the cloud provider you use (eg. AWS Block Store, Azure File, Azure Disk, Google Cloud Persistent Disk)
                - `kubectl describe storageclass` -> for more details, use this command