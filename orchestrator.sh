#!/bin/bash

case $1 in
  create)
    vagrant up
    echo "cluster created"
    ;;

  start)
    vagrant up
    echo "cluster started"
    ;;

  stop)
    vagrant halt
    echo "cluster stopped"
    ;;

  destroy)
    vagrant destroy -f
    echo "cluster destroyed"
    ;;

  status)
    vagrant status
    ;;

  build)
    ./scripts/build-images.sh
    ;;

  push)
    ./scripts/push-images.sh
    ;;

  deploy)
    ./scripts/deploy-all.sh
    ;;

  *)
    echo "Usage: $0 {create|start|stop|destroy|status|build|push|deploy}"
    exit 1
    ;;
esac
