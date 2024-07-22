# Fibonacci-calculator
- A simple fibonacci sequence calculator application created to showcase complex application deployment with automated CI/CD integration:
    - `React` frontend
    - `Express` backend
    - Store data in `redis` and in `postgres` (intentional complexity for practice purposes!)
    - Use `nginx` to route incoming requests in development

# Start
### Development:
- clone the repo:
    - `git clone https://github.com/gakalmar/fibonacci-calculator.git`
- from the project root in a terminal:
    - `minikube start`
    - `kubectl apply -f k8s` (applies all files in the k8s folder)
    - Connect:
        - On Windows:
            - `minikube tunnel`
            - connect to localhost through your browser
        - On Mac:
            - `minikube ip`
            - connect to minikube's IP directly, through your browser

### Production:
- Project is not live yet
