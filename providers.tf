provider "helm" {
  kubernetes {
    host                   = module.create_cluster.eks_cluster_url
    cluster_ca_certificate = module.create_cluster.eks_cluster_cacertificate
    token                  = module.create_cluster.eks_cluster_token
  }
}

provider "kubernetes" {
  host                   = module.create_cluster.eks_cluster_url
  cluster_ca_certificate = module.create_cluster.eks_cluster_cacertificate
  token                  = module.create_cluster.eks_cluster_token
}


provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      project = var.project_name
    }
  }
}

