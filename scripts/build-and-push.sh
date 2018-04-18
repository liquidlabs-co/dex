#!/bin/bash -e

TAG=${TAG-latest}

if [ "$KOPS_CLOUD_PROVIDER" = "aws" ]; then
  AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID-569325332953}
  REGION=${AWS_REGION-us-east-1}

  REPO_URI=$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
  DOCKER_REPO=$REPO_URI/dex
  DOCKER_REPO_EXAMPLE_APP=$REPO_URI/dex-signin

  make build
  make docker-image
  make docker-image-example-app

  $(aws ecr get-login --no-include-email --region $REGION)
  docker push $DOCKER_REPO:$TAG
  docker push $DOCKER_REPO_EXAMPLE_APP:$TAG
elif [ "$KOPS_CLOUD_PROVIDER" = "gcp" ]; then
  REPO_URI=gcr.io/$GCP_PROJECT_ID
  DOCKER_REPO=$REPO_URI/dex
  DOCKER_REPO_EXAMPLE_APP=$REPO_URI/dex-signin

  make build
  make docker-image
  make docker-image-example-app

  eval $(gcloud auth configure-docker)
  docker push $DOCKER_REPO:$TAG
  docker push $DOCKER_REPO_EXAMPLE_APP:$TAG
else
  echo "Unsupported KOPS_CLOUD_PROVIDER '${KOPS_CLOUD_PROVIDER}'."
  echo "Available providers: aws, gcp"
  exit 1
fi
