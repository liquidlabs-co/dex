#!/bin/bash -e

AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID-569325332953}
REGION=${AWS_REGION-us-east-1}
TAG=${TAG-latest}

ECR_BASE=$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
DOCKER_REPO=$ECR_BASE/dex
DOCKER_REPO_EXAMPLE_APP=$ECR_BASE/dex-signin

make build
make docker-image
make docker-image-example-app

$(aws ecr get-login --no-include-email --region $REGION)
docker push $DOCKER_REPO:$TAG
docker push $DOCKER_REPO_EXAMPLE_APP:$TAG
