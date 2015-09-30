set -e
set -o pipefail
echo "getting op config"
git clone https://github.com/CTCL/op_config_tool.git /usr/src/op_config_tool
cd /usr/src/op_config_tool
. ./setup.sh
echo "fetching op config file"
. ./fetch.sh
echo "setting up github credentials"
aws s3 cp s3://$OP_CONFIG_BUCKET/$PRIVATE_KEY_FILE ~/.ssh/$PRIVATE_KEY_FILE
chmod 600 ~/.ssh/$PRIVATE_KEY_FILE
ssh-keyscan github.com >> ~/.ssh/known_hosts
eval `ssh-agent -s`
ssh-add ~/.ssh/$PRIVATE_KEY_FILE
#echo "machine github.com login $(opc GITHUB_USER) password $(opc GITHUB_PASSWORD)" > /root/.netrc
echo "cloning repo to build"
git clone $GIT_REPO_URL repodir
cd repodir
tar --exclude-vcs -cvzf repo.tar.gz *

echo "building image for ${DOCKER_REPO_NAME}"
curl -f -sS -X POST -H "Content-Type:application/tar" --data-binary '@repo.tar.gz' --unix-socket /var/run/docker.sock http:/build?t=$DOCKER_REPO_NAME:$(opc DOCKER_TAG)

echo "creating container for tests"
container_id=$(curl -f -sS -X POST -H "Content-Type:application/json" --data-binary "{\"Image\": \"$DOCKER_REPO_NAME:$(opc DOCKER_TAG)\", \"Cmd\": [\"/bin/sh\", \"-c\", \"$TEST_COMMAND\"]}" --unix-socket /var/run/docker.sock http:/containers/create | python -c "import sys, json; print json.load(sys.stdin)['Id']")

echo "starting container for tests"
curl -f -sS -X POST --unix-socket /var/run/docker.sock http:/containers/$container_id/start
running=$(curl -f -sS --unix-socket /var/run/docker.sock http:/containers/$container_id/json | python -c "import sys,json; print json.load(sys.stdin)['State']['Running']")
while [ $running == "True" ]
do
  running=$(curl -f -sS --unix-socket /var/run/docker.sock http:/containers/$container_id/json | python -c "import sys,json; print json.load(sys.stdin)['State']['Running']")
done
exitcode=$(curl -f -sS --unix-socket /var/run/docker.sock http:/containers/$container_id/json | python -c "import sys,json; print json.load(sys.stdin)['State']['ExitCode']")
if [ $exitcode -ne "0" ]
then
  exit $exitcode
fi

echo "creating registry header"
registry_header=$(python -c "import base64, json; print base64.b64encode(json.dumps({'username': '$(opc DOCKERHUB_USER)', 'password':'$(opc DOCKERHUB_PASSWORD)', 'email':'$(opc DOCKERHUB_EMAIL)'}))")

echo "pushing to registry"
curl -f -sS -X POST -H "X-Registry-Auth: $registry_header" --unix-socket /var/run/docker.sock http:/images/$DOCKER_REPO_NAME/push
