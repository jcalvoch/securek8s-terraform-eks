# Deploy a private K8s cluster and required authorization in one step using Terraform and EKS
This is a template I created to mainly cover two main gaps in all the examples I found in others posts:
- There was a lack of documentation regarding how to deploy private clusters and this is surprising as many security teams will probably go nuts if you deploy a 0.0.0.0/0 allowed cluster with a public endpoint.
- Normally you need to deploy additional things besides a cluster (ingress controller and eks-auth for example) and at the time I did this there was no post closing that gap with Terraform.


## Features on this Terraform template
- VPC creation, including required tags and VPC endpoints for private access
- Creation of required IAM Roles
- Creation of the EKS Kubernetes cluster
- Creation of EKS nodes
- Kubernetes etcd encryption enabled using AWS KMS service
- Let's Encrypt certificate creation via cert-manager using Route53 validation ready
- Cluster IAM Roles for service account (IRSA) ready
- Creates a user called "app-user" (or whatever you choose by defining the value of the variable) and gives it administrator permissions to the cluster
- Adds administrator permissions to the cluster to Administrator SSO IAM Role for those interested of learning this for SSO roles
- Deploys ingress controller using NGINX
- Cluster observability using Container Insights and Prometheus

## Note: Remember that this cluster is accesible via a private IP (VPC) only so you will need to add additional code to allow this new VPC to be accesible from the computer executing the Terraform script via either a bastion host or a Direct Connect or VPN Connection. Otherwise, set the "endpoint_public_access" to "True" initially (and perhaps only allow your IP) and set it to off once you have the connectivity part in place.