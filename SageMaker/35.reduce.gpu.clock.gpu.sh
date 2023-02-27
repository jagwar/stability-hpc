#!/bin/bash
set -x
set -e

reduceClock() {
    wget -O /tmp/aws-gpu-reduce-clock.sh 'https://raw.githubusercontent.com/jagwar/stability-hpc/main/SageMaker/custom-scripts-and-configs/aws-gpu-reduce-clock.sh'
    wget -O /tmp/aws-gpu-reduce-clock.service 'https://raw.githubusercontent.com/jagwar/stability-hpc/main/SageMaker/custom-scripts-and-configs/aws-gpu-reduce-clock.service'
    sudo mv /tmp/aws-gpu-reduce-clock.sh /opt/aws/ && chmod +x /opt/aws/aws-gpu-reduce-clock.sh
    sudo mv /tmp/aws-gpu-reduce-clock.service /lib/systemd/system
    sudo systemctl enable aws-gpu-reduce-clock.service && sudo systemctl start aws-gpu-reduce-clock.service
}


# main
# ----------------------------------------------------------------------------
main() {
    echo "[INFO][$(date '+%Y-%m-%d %H:%M:%S')] 35.reduce.gpu.clock.gpu.sh: START" >&2
    reduceClock
    echo "[INFO][$(date '+%Y-%m-%d %H:%M:%S')] 35.reduce.gpu.clock.gpu.sh: STOP" >&2
}

main "$@"
