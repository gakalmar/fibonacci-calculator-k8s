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
    2. Test the setup locally on minikube
    3. Create a Github/Travis flow to build images and deploy
    4. Deploy the app to a cloud provider