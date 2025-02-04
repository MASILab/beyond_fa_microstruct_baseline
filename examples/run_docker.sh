#!/bin/bash
input_dir="/fs5/p_masi/saundam1/outputs/beyond_fa/inputs"
output_dir="/fs5/p_masi/saundam1/outputs/beyond_fa/outputs"

metrics=("md" "fa" "rd" "ad" "ga")

for metric in "${metrics[@]}"; do
    mkdir -p ${output_dir}_$metric
    
    DOCKER_NOOP_VOLUME="beyondfa_baseline-volume"
    sudo docker volume create "$DOCKER_NOOP_VOLUME" > /dev/null
    sudo docker run \
        -it \
        --platform linux/amd64 \
        --network none \
        --gpus all \
        --rm \
        --volume $input_dir:/input:ro \
        --volume ${output_dir}_$metric:/output \
        --volume "$DOCKER_NOOP_VOLUME":/tmp \
        --volume /nfs:/nfs:ro \
        beyondfa_baseline:$metric sh
    sudo docker volume rm "$DOCKER_NOOP_VOLUME" > /dev/null
done