#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

set -x
set -e

configureFederatedSlurmDBD(){
    # slurm accounting must be preinstalled in the VPC.
    # slurm accouting secrets must be defined
    aws s3 cp --quiet "${post_install_base}/sacct/slurm/slurm_fed_sacct.conf" /tmp/ --region "${cfn_region}" || exit 1
    aws s3 cp --quiet "${post_install_base}/sacct/slurm/munge.key.gpg" /tmp/ --region "${cfn_region}" || exit 1
    export SLURM_FED_DBD_HOST="$(aws secretsmanager get-secret-value --secret-id "SLURM_FED_DBD_HOST" --query SecretString --output text --region "${cfn_region}")"
    export SLURM_FED_PASSPHRASE="$(aws secretsmanager get-secret-value --secret-id "SLURM_FED_PASSPHRASE" --query SecretString --output text --region "${cfn_region}")"
    /usr/bin/envsubst < slurm_fed_sacct.conf > "${SLURM_ETC}/slurm_sacct.conf"
    echo "include slurm_sacct.conf" >> "${SLURM_ETC}/slurm.conf"
    gpg --batch --passphrase "$SLURM_FED_PASSPHRASE" -d -o munge.key munge.key.gpg
    mv -f munge.key /etc/munge/munge.key
    chown munge:munge /etc/munge/munge.key
    chmod 600 /etc/munge/munge.key
    cp /etc/munge/munge.key /home/ec2-user/.munge/.munge.key
}

patchSlurmConfig() {
	sed -i "s/ClusterName=parallelcluster.*/ClusterName=parallelcluster-${stack_name}/" "/opt/slurm/etc/slurm.conf"
    sed -i "s/SlurmctldPort=6820-6829/SlurmctldPort=6820-6849/" "/opt/slurm/etc/slurm.conf"
    rm -f /var/spool/slurm.state/clustername
    ifconfig eth0 txqueuelen 512
}

restartSlurmDaemons() {
    set +e
    systemctl restart munge
    /opt/slurm/bin/sacctmgr -i create cluster ${stack_name}
    /opt/slurm/bin/sacctmgr -i create account name=none
    /opt/slurm/bin/sacctmgr -i create user ${cfn_cluster_user} cluster=${stack_name} account=none
    systemctl restart slurmctld
}

# main
# ----------------------------------------------------------------------------
main() {
    echo "[INFO][$(date '+%Y-%m-%d %H:%M:%S')] 03.configure.slurm.acct.headnode.sh: START" >&2
    configureFederatedSlurmDBD
    patchSlurmConfig
    restartSlurmDaemons
    echo "[INFO][$(date '+%Y-%m-%d %H:%M:%S')] 03.configure.slurm.acct.headnode.sh: STOP" >&2
}

main "$@"