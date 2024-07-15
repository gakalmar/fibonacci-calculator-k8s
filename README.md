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
        - `client-deployment.yaml`
        - `client-cluster-ip-service.yaml`
        - `server-deployment.yaml` (we will have to add also the ENV variables for Redis and Postgres!)
        - `server-cluster-ip-service.yaml`
        - `worker-deployment.yaml` (we will have to add also the ENV variables for Redis and Postgres! But no service or port setup is needed, because we are only connecting FROM it, not TO it)

        - Config files can also be combined (eg. add the service and the deployment in a single file, that work together):
            - We just need to copy them one after the other in the file, and separate them with a `---` line
    
    2. Test the setup locally on minikube:
        - to apply a group of config files:
            - `kubectl apply -f k8s` (we refer to the folder, and everything inside it will be applied)
            
    3. Create a Github/Travis flow to build images and deploy
    4. Deploy the app to a cloud provider

- Kubernetes Object descriptions:
    - `ClusterIP` service:
        - services in general: objects that are used to create networking in a cluster
        - more restrictive than a `NodePort`
        - exposes pods to other objects **within the cluster** (no external access is allowed!)
        - only uses `port` and `targetPort` (because it's not reachable form outside)
            - `port` is through what other k8s objects reach the object (eg. deployment) the service is attached to
            - `targetPort` is the port the service is connected to (eg. the exposed port of the deployment)
        - specify `type` as `ClusterIP`