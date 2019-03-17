#!/usr/bin/env bash
set -e

#usage:
# CUDA_VISIBLE_DEVICES=0 ./grid_run.sh \
#    --redis-port 12001 \
#    --config ..../config.yml \
#    --logdir ..../logdir/log-prefix \
#    --param-name "trainer/start_learning" \
#    --param-values "10, 20, 30" \
#    --param-type "int" \
#    --wait-time 30 \
#    --n-trials 3

REDIS_PORT=
CONFIG=
LOGDIR=
PARAM_NAME=
PARAM_VALUES=
PARAM_TYPE=
WAIT_TIME=
N_TRIALS=


while (( "$#" )); do
  case "$1" in
    --redis-port)
      REDIS_PORT=$2
      shift 2
      ;;
    --config)
      CONFIG=$2
      shift 2
      ;;
    --logdir)
      LOGDIR=$2
      shift 2
      ;;
    --param-name)
      PARAM_NAME=$2
      shift 2
      ;;
    --param-values)
      PARAM_VALUES=$2
      shift 2
      ;;
    --param-type)
      PARAM_TYPE=$2
      shift 2
      ;;
    --wait-time)
      WAIT_TIME=$2
      shift 2
      ;;
    --n-trials)
      N_TRIALS=$2
      shift 2
      ;;
    *) # preserve positional arguments
      shift
      ;;
  esac
done


IFS=',' read -r -a PARAM_VALUES <<< "$PARAM_VALUES"

for ((trial=0; trial<N_TRIALS; trial++)) ; do
        for param_value in  ${PARAM_VALUES[@]} ; do
        param_name=${PARAM_NAME/"/"/"-"}
        redis_prefix=${param_name}-${param_value}-${trial}

        REDIS_PORT="$(($REDIS_PORT+1))"
        redis-server --port "${REDIS_PORT}" &
        pid1=$!

        RUN_PARAMS="--config=${CONFIG}
        --logdir=${LOGDIR}-${redis_prefix}
        --${PARAM_NAME}=${param_value}:${PARAM_TYPE}
        --redis/port=${REDIS_PORT}:int
        --redis/prefix=${redis_prefix}:str"
        echo $RUN_PARAMS

        sleep 5
        catalyst-rl run-trainer ${RUN_PARAMS} &
        sleep 10
        CUDA_VISIBLE_DEVICES="" catalyst-rl run-samplers ${RUN_PARAMS} &
        sleep 10
        sleep ${WAIT_TIME}

        sleep 1
        kill -9 $(ps aux | grep -i "catalyst-rl run-samplers ${RUN_PARAMS}" | awk '{print $2}')
        sleep 1
        kill -9 $(ps aux | grep -i "catalyst-rl run-trainer ${RUN_PARAMS}" | awk '{print $2}')
        sleep 1

#        set +e
        kill -9 $pid1
        sleep 1
#        kill -9 $(ps aux | grep -i -e "redis-server \*:${REDIS_PORT}" | awk '{print $2}')
#        sleep 1
#        kill -9 $pid
#        sleep 1
#        kill -9 $(ps aux | grep -i -e "redis-server \*:${REDIS_PORT}" | awk '{print $2}')
#        sleep 1
#        set -e

        sleep 5
    done
done
