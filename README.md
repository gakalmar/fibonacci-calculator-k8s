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
        
        - Configure environment variables:
            - `server` needs:
                - `REDIS_HOST` (constant value, but of URL type - describes how to connect to service - use the name of the service!)
                - `REDIS_PORT` (constant value)
                - `PGUSER` (constant value)
                - `PGHOST` (constant value, but of URL type - describes how to connect to service - use the name of the service!)
                - `PGDATABASE` (constant value)
                - `PGPORT` (constant value)
                - `POSTGRES-PASSWORD` (used with a secret)
            - `worker` needs:
                - `REDIS_HOST` (constant value, but of URL type - describes how to connect to service - use the name of the service!)
                - `REDIS_PORT` (constant value)
            
            - `server-deployment.yaml`:
                - add `env` to `templates/containers` section
                    - `REDIS_HOST` and `PGHOST` values are the names of the services we are connecting to, so:
                        - `redis-cluster-ip-service`
                        - `postgres-cluster-ip-service`
            - `worker-deployment.yaml`:
                - add `env` to `templates/containers` section (only redis needs to be added)
            - For the final variable, we use a secret with an imperative command to create it locally (see below at `Secret` object section)
                - we need to add this also as an env variable to our `server-deployment.yaml` file (instead of `value`, we use `valueFrom`/`secretKeyRef`)
                - we also need to add this to our `postgres-deployment.yaml` file!

        - Config files can also be combined (eg. add the service and the deployment in a single file, that work together):
            - We just need to copy them one after the other in the file, and separate them with a `---` line
        
        - Setting up `ngress` (https://kubernetes.github.io/ingress-nginx/deploy/):
            - Setup `ingress` locally: 
                - make sure you have `minikube` running!
                - `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml`
                - `minikube addons enable ingress`
            - Create config file with these routing rules:
                - `/` path is forwarded to `client`
                - `/api` path is forwarded to the `server`

    2. Test the setup locally on minikube:
        - to apply a group of config files:
            - `kubectl apply -f k8s` (we refer to the folder, and everything inside it will be applied)
        - then connect with:
            - `minikube tunnel` -> connect to `127.0.0.1` (localhost) in your browser

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
                - `kubectl get pv` `... pvc`-> list PVs or PVCs
    
    - `Secret`:
        - it's also a kubernetes object, that we can create, which is used to securely store information in the cluster (SSH key, password, connection string, etc.)
        - in this case, we create it with an imperative command, instead of the declarative config file (because if we write a config file for it, the secret would still be legible from the config file -> this means that in the production environment we will also have to create this secret!):
            - `kubectl create secret generic <secret_name> --from-literal key=value`
            - `kubectl create secret generic pgpassword --from-literal POSTGRES_PASSWORD=postgres_password`
        - To see what secrets have been created, use the follwing command:
            - `kubectl get secrets` (it will not reveal the actual key-value pairs, just then `<secret_name>` under which the kvps are stored)
    
    - `LoadBalancer`:
        - Legacy way of allowing network traffic into a cluster
        - Allows traffic into 1 specific set of pods only, so we would need as many as the number of deployments we need to expose  

    - `Ingress`:
        - A special kind of `Service`, which allows external traffic into a set of deployments and other Kubernetes objects
        - There are multiple implementations of an `Ingress`, we will use the `ingress-nginx` that is a project developed officially by Kubernetes (this is from `github.com/kubernetes/ingress-nginx`)
            - as opposed to `kubernetes-ingress`, which is a project developed by `nginx` (`github.com/nginxinc/kubernetes-ingress`)
        - implementing `ingress-nginx` will create an ingress locally, but when deploying it to a cloud environment, it will create a second ingress based on the cloud provider, and the setup will be different for each one of them!
        - `Controller`:
            - Previously we created a `config` file that was fed into `kubectl`, so that the running `deployment` could look at it and check the *current state* vs. the *desired state*, and do as it was supposed to. The `deployment` in this case is considered a `controller`
            - In the world of ingresses it works the same way, but the object we create with the `config` file is called an `Ingress controller`, which makes sure the *current state* is always up-to-date with the *desired state*

        - **Summary:**
            - We have an `ingress config file`, that creates an `ingress controller`, that is then creating a `traffic-forwarding element` in our infrastructure
            - In our case with the `ingress-nginx` setup this `traffic forwarding element` will be the same as the controller, so no separated thing is created!
            - When we set this up on a Cloud Provider, a 2nd ingress service is created by the provider, which is specific to that provider:
                - With `Google Cloud` specifically:
                    - Traffic comes into the `GC Load Balancer` (still in the cloud!)
                    - Traffic is forwarded to the `Load Balancer Service` (this is inside our cluster)
                    - The `Load Balancer Service` is connected to a `deployment`, that has a container running with the combined `nginx controller/nginx pod`
                    - The `Load Balancer Service` and the `deployment` inside are created using an `ingress config file`, which includes a set of routing rules
                    - The `ingress-nginx` project we are using also creates a `default backend`, which is another `deployment`-`cluster-ip-service` setup on the same level as our `client` and `server` deployments (this is ideally replaced by your app's backend, eg express server)
        