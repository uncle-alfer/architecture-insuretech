PY ?= python3
VENV_DIR ?= .venv
REQUIREMENTS ?= requirements.txt

.PHONY: venv deps

venv:
	$(PY) -m venv $(VENV_DIR)

deps: venv
	. $(VENV_DIR)/bin/activate && pip install -U pip && pip install -r $(REQUIREMENTS)

nonsudo-docker:
	sudo usermod -aG docker $$USER
	newgrp docker

start-cluster:
	minikube start --driver=docker --addons=metrics-server

check-cluster:
	minikube status || true
	kubectl top nodes || true
	kubectl top pods  || true

deploy:
	kubectl apply -f Task2/deployment.yaml
	kubectl apply -f Task2/service.yaml

check-url:
	kubectl get svc scaletestapp -o wide
	minikube ip
	minikube service scaletestapp --url
	curl $$(minikube service scaletestapp --url | grep -E '^http' | head -n1)

deploy-hpa:
	kubectl apply -f Task2/hpa.yaml

check-hpa:
	kubectl get hpa scaletestapp-hpa -w

run-locust: deps
	locust -f Task2/locustfile.py --host $$(minikube service scaletestapp --url | grep -E '^http' | head -n1)
