#!/bin/bash

# Fetch credentials for clusters across multiple projects
# Usage: ./gcloud.sh cluster-name region project1 [project2 ...]

NAME=$1
REGION=$2
shift 2

for PROJECT in "$@"; do
  echo "Fetching credentials for $NAME in $PROJECT"
  gcloud container clusters get-credentials "$NAME" --region="$REGION" --project="$PROJECT"
done
