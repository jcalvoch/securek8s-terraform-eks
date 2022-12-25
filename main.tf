data "aws_caller_identity" "current" {}

module "create_vpc" {
  source       = "./modules/vpc"
  profile      = var.profile
  region       = var.region
  environment  = var.environment
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

module "create_cluster" {
  source            = "./modules/eks"
  subnet_ids        = module.create_vpc.private_subnet_ids
  security_group_id = module.create_vpc.eks_securitygroup_id
  profile           = var.profile
  environment       = var.environment
  project_name      = var.project_name
  account_id        = data.aws_caller_identity.current.account_id
  region            = var.region
}

module "helm" {
  source          = "./modules/helm"
  region          = var.region
  amp_rolearn     = module.amp.amp_rolearn
  amp_workspaceid = module.amp.amp_workspaceid
  depends_on = [
    module.create_cluster
  ]
}

module "amp" {
  source            = "./modules/amp"
  environment       = var.environment
  project_name      = var.project_name
  account_id        = data.aws_caller_identity.current.account_id
  oidc_provider_url = module.create_cluster.eks_oidc_provider_url
}

module "container-insights" {
  source       = "./modules/container-insights"
  region       = var.region
  environment  = var.environment
  project_name = var.project_name
  cluster_name = module.create_cluster.eks_cluster_name
  depends_on = [
    module.create_cluster
  ]
}


module "eks-auth" {
  source         = "./modules/eks-auth"
  account_id     = data.aws_caller_identity.current.account_id
  nodegroup_role = module.create_cluster.eks_nodegroup_role
  user_name      = var.user_name
  depends_on = [
    module.create_cluster
  ]
}




module "cert-manager" {
  source            = "./modules/cert-manager"
  environment       = var.environment
  project_name      = var.project_name
  region            = var.region
  oidc_provider_url = module.create_cluster.eks_oidc_provider_url
  route53_zoneid    = var.route53_zoneid
  account_id        = data.aws_caller_identity.current.account_id
}


module "iam" {
  source       = "./modules/iam"
  environment  = var.environment
  project_name = var.project_name
  user_name    = var.user_name
}
