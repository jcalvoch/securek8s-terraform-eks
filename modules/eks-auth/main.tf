data "aws_iam_roles" "admin" {
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
}


data "aws_iam_roles" "viewOnly" {
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
  name_regex  = "AWSReservedSSO_ViewOnlyAccess_.*"
}


resource "kubernetes_cluster_role_binding" "custom-cluster-admins" {
  metadata {
    name = "custom-cluster-admins"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = "custom-cluster-admins"
    api_group = "rbac.authorization.k8s.io"
    namespace = ""
  }

}

resource "kubernetes_cluster_role_binding" "user1" {
  metadata {
    name = var.user_name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = var.user_name
    api_group = "rbac.authorization.k8s.io"
    namespace = ""
  }

}


resource "kubernetes_config_map_v1_data" "aws-auth" {
  force = true
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = yamlencode([
      {
        "groups" : [
          "system:bootstrappers",
          "system:nodes"
        ],
        "rolearn" : "${var.nodegroup_role}",
        "username" : "system:node:{{EC2PrivateDNSName}}"
      },
      {
        "groups" : [
          "system:masters"
        ],
        "rolearn" : "arn:aws:iam::${var.account_id}:role/AWSReservedSSO_AdministratorAccess_${replace(tolist(data.aws_iam_roles.admin.arns)[0], "/a.*_/", "")}",
        "username" : "custom-cluster-admins"
      }
    ])
    mapUsers = yamlencode([
      {
        "groups" : [
          "system:masters"
        ],
        "userarn" : "arn:aws:iam::${var.account_id}:user/${var.user_name}"
      }
    ])
  }

}
