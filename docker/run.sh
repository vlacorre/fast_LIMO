#!/bin/bash
set -e

xhost +local:root

DOCKER_NAME="fastlimo-container"
DOCKER_IMG="fastlimo-ros2-image:latest"

XAUTH=/tmp/.docker.xauth
PROJECT_ROOT="$(cd "$(dirname "$0")"; pwd)"

if docker ps -l | grep -q ${DOCKER_NAME}; then
  echo "WARNING: A container named ${DOCKER_NAME} was already created; it will be removed"
  docker rm ${DOCKER_NAME} &> /dev/null
fi

docker run -it --rm \
  --name ${DOCKER_NAME} \
  --env="DISPLAY=$DISPLAY" \
  --env="QT_X11_NO_MITSHM=1" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  --env="XAUTHORITY=$XAUTH" \
  --net=host \
  --privileged \
  ${DOCKER_IMG} "$@"

xhost -local:root
echo "Goodbye :)"