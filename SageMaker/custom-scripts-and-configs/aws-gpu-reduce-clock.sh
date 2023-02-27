#!/bin/bash

if [ ! nvidia-smi ]; then
   echo "nvidia-smi not found"
   exit 0
fi

GPUNAME=$(nvidia-smi -L | head -n1)
echo $GPUNAME

if [[ $GPUNAME == *"A100-SXM4-80GB"* ]]; then
   nvidia-smi -lgc 210,1305
else
   echo "unsupported gpu"
fi
