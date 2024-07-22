docker bulid -t gakalmar/fibonacci-calculator-client:latest -t gakalmar/fibonacci-calculator-client:$SHA -f ./client/Dockerfile ./client
docker bulid -t gakalmar/fibonacci-calculator-server:latest -t gakalmar/fibonacci-calculator-server:$SHA -f ./server/Dockerfile ./server
docker bulid -t gakalmar/fibonacci-calculator-worker:latest -t gakalmar/fibonacci-calculator-worker:$SHA -f ./worker/Dockerfile ./worker

docker push gakalmar/fibonacci-calculator-client:latest
docker push gakalmar/fibonacci-calculator-server:latest
docker push gakalmar/fibonacci-calculator-worker:latest

docker push gakalmar/fibonacci-calculator-client:$SHA
docker push gakalmar/fibonacci-calculator-server:$SHA
docker push gakalmar/fibonacci-calculator-worker:$SHA

kubectl apply -f k8s
kubectl set image deployments/client-deployment client=gakalmar/fibonacci-calculator-client:$SHA
kubectl set image deployments/server-deployment server=gakalmar/fibonacci-calculator-server:$SHA
kubectl set image deployments/worker-deployment worker=gakalmar/fibonacci-calculator-worker:$SHA