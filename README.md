# building docker images to build docker images to build docker images
This builds a docker image that can be run with 4 environment variables:
* GIT_REPO_URL - The URL of a repo to check out
* DOCKER_REPO_NAME - the tag of the docker image you want to build from the repo
* OP_CONFIG_BUCKET - the s3 bucket location of an op config file
* OP_CONFIG_FILE (optional, defaults to op.cfg) - the file name of the op config file

The op config file should contain the following:
* DOCKERHUB_USER
* DOCKERHUB_EMAIL
* DOCKERHUB_PASSWORD
* DOCKER_TAG
* GITHUB_USER
* GITHUB_PASSWORD
* TEST_COMMAND
