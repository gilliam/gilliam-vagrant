#!/bin/bash

set -x

sed 's/main$/main universe/' -i /etc/apt/sources.list
apt-get -qq update
apt-get -qq install -y curl python python-pip git > /dev/null

curl https://get.docker.io/gpg | apt-key add -
echo "deb http://get.docker.io/ubuntu docker main" > /etc/apt/sources.list.d/docker.list
apt-get -qq update
apt-get -qq install --force-yes lxc-docker > /dev/null
# XXX: right not we're running over HTTP to support WebSocket.
sed -i "s#docker -d#docker -d -H 0.0.0.0:3000#g" /etc/init/docker.conf
service docker restart
sleep 3

HOST=192.168.33.10
OPTIONS="-H $HOST:3000"

docker $OPTIONS run -d gilliam/service-registry -n name -c name 
sleep 3
docker $OPTIONS run -e GILLIAM_SERVICE_REGISTRY=$HOST:3222 -e DOCKER=http://192.168.33.10:3000 -d gilliam/executor --host $HOST --name vagrant-1
sleep 3
docker $OPTIONS run -e GILLIAM_SERVICE_REGISTRY=$HOST:3222 -e ROUTERS=vagrant-1 gilliam/bootstrap
sleep 3

pip -q install git+https://github.com/gilliam/gilliam-py.git
pip -q install git+https://github.com/gilliam/client.git

cat > /etc/profile.d/gilliam.sh <<EOF
export GILLIAM_SERVICE_REGISTRY=$HOST:3222
EOF

echo "Done!"
