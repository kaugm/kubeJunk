#!/usr/bin/env bash

# Usage: ./create.sh
# Edits: Change cluster_name and region, below to modify the cluster
# Edits: Modify template.yaml to change any default settings of the EKS cluster

# Set Default Values
cluster_name="karl-eks"
region="us-west-2"

# Get (Optional) Arguments
while getopts n:r: flag
do
	case "${flag}" in
		n) cluster_name=${OPTARG} ;;
		r) region=${OPTARG} ;;
	esac
done

# Check if at least 1 available Elastic IP
num_eips=$(aws ec2 describe-addresses --region $region | jq  '.Addresses | length')

if [[ $num_eips -eq 5 ]]
then
	echo "Maximum number of Elastic IP(s) used for $region. Stopping..."
	exit
else
	echo "$((5 - $num_eips)) Elastic IP(s) available in $region. Continuing..."
fi

# Create Custom cluster.yaml from Template and Inject Dynamic Tag Values
sed "s/DATE/$(date -v+72H '+%m.%d.%Y')/g" template.yaml > $(date '+%m%d').yaml
sed -i '' "s/CLUSTERNAME/$cluster_name/g" $(date '+%m%d').yaml
sed -i '' "s/REGION/$region/g" $(date '+%m%d').yaml

# Create Cluster
echo "Creating cluster with $(date '+%m%d').yaml ..."
eksctl create cluster -f $(date '+%m%d').yaml

# Update kubeconfig and output final comments
aws eks --region $region update-kubeconfig --name $cluster_name
#echo "Run: aws eks --region us-west-2 update-kubeconfig --name [ CLUSTER_NAME ]"
echo "To delete cluster, first delete any nodegroups created and then run: eksctl delete cluster -f $(date '+%m%d').yaml"
echo "OPTIONAL: Please edit the node security group to allow for communication on port 80"
