resource "kubernetes_namespace" "amazon-cloudwatch" {
  metadata {

    labels = {
      name = "amazon-cloudwatch"
    }

    name = "amazon-cloudwatch"
  }
}

resource "kubernetes_service_account" "cloudwatchagent" {
  depends_on = [
    kubernetes_namespace.amazon-cloudwatch
  ]
  metadata {
    name      = "cloudwatch-agent"
    namespace = "amazon-cloudwatch"
  }

}

resource "kubernetes_cluster_role" "cloudwatch-agent-role" {
  depends_on = [
    kubernetes_namespace.amazon-cloudwatch
  ]
  metadata {
    name = "cloudwatch-agent-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "nodes", "endpoints"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["replicasets"]
    verbs      = ["list", "watch"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes/proxy"]
    verbs      = ["get"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes/stats", "configmaps", "events"]
    verbs      = ["create"]
  }
  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["cwagent-clusterleader"]
    verbs          = ["get", "update"]
  }
}

resource "kubernetes_cluster_role_binding" "cloudwatch-agent-role-binding" {
  depends_on = [
    kubernetes_namespace.amazon-cloudwatch
  ]
  metadata {
    name = "cloudwatch-agent-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cloudwatch-agent-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cloudwatch-agent"
    namespace = "amazon-cloudwatch"
  }

}

resource "kubernetes_config_map" "cwagentconfig" {
  depends_on = [
    kubernetes_namespace.amazon-cloudwatch
  ]
  metadata {
    name      = "cwagentconfig"
    namespace = "amazon-cloudwatch"
  }
  data = {
    "cwagentconfig.json" = <<EOT
     {
      "agent" : {
        "region" : "${var.region}"
      },
      "logs" : {
        "metrics_collected" : {
          "kubernetes" : {
            "cluster_name" : "${var.cluster_name}",
            "metrics_collection_interval" : 60
          }
        },
        "force_flush_interval" : 5
      }
    }
    EOT
  }

}

resource "kubernetes_daemonset" "cloudwatch-agent" {
  depends_on = [
    kubernetes_namespace.amazon-cloudwatch
  ]
  metadata {
    name      = "cloudwatch-agent"
    namespace = "amazon-cloudwatch"

  }

  spec {
    selector {
      match_labels = {
        name = "cloudwatch-agent"
      }
    }

    template {
      metadata {
        labels = {
          name = "cloudwatch-agent"
        }
      }

      spec {
        container {
          image = "amazon/cloudwatch-agent:1.247352.0b251908"
          name  = "cloudwatch-agent"

          resources {
            limits = {
              cpu    = "200m"
              memory = "200Mi"
            }
            requests = {
              cpu    = "200m"
              memory = "200Mi"
            }
          }
          env {
            name = "HOST_IP"
            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }
          env {
            name = "HOST_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name = "K8S_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          env {
            name  = "CI_VERSION"
            value = "k8s/1.3.10"

          }

          volume_mount {
            name       = "cwagentconfig"
            mount_path = "/etc/cwagentconfig"
          }
          volume_mount {
            name       = "rootfs"
            mount_path = "rootfs"
            read_only  = true
          }
          volume_mount {
            name       = "dockersock"
            mount_path = "/var/run/docker.sock"
            read_only  = true
          }
          volume_mount {
            name       = "varlibdocker"
            mount_path = "/var/lib/docker"
            read_only  = true
          }
          volume_mount {
            name       = "containerdsock"
            mount_path = "/run/containerd/containerd.sock"
            read_only  = true
          }
          volume_mount {
            name       = "sys"
            mount_path = "/sys"
            read_only  = true
          }
          volume_mount {
            name       = "devdisk"
            mount_path = "/dev/disk"
            read_only  = true
          }

        }
        volume {
          name = "cwagentconfig"
          config_map {
            name = "cwagentconfig"
          }
        }
        volume {
          name = "rootfs"
          host_path {
            path = "/"
          }
        }
        volume {
          name = "dockersock"
          host_path {
            path = "/var/run/docker.sock"
          }
        }
        volume {
          name = "varlibdocker"
          host_path {
            path = "/var/lib/docker"
          }
        }
        volume {
          name = "containerdsock"
          host_path {
            path = "/run/containerd/containerd.sock"
          }
        }
        volume {
          name = "sys"
          host_path {
            path = "/sys"
          }
        }
        volume {
          name = "devdisk"
          host_path {
            path = "/dev/disk/"
          }
        }
        termination_grace_period_seconds = 60
        service_account_name             = "cloudwatch-agent"
      }
    }
  }
}

resource "kubernetes_config_map" "fluent-bit-cluster-info" {
  depends_on = [
    kubernetes_namespace.amazon-cloudwatch
  ]
  metadata {
    name      = "fluent-bit-cluster-info"
    namespace = "amazon-cloudwatch"
  }

  data = {
    "cluster.name" = var.cluster_name
    "logs.region"  = var.region
    "http.server"  = "On"
    "http.port"    = 2020
    "read.head"    = "Off"
    "read.tail"    = "On"
  }

}

resource "kubernetes_service_account" "fluent-bit" {
  depends_on = [
    kubernetes_namespace.amazon-cloudwatch
  ]
  metadata {
    name      = "fluent-bit"
    namespace = "amazon-cloudwatch"
  }
}

resource "kubernetes_cluster_role" "fluent-bit-role" {
  depends_on = [
    kubernetes_namespace.amazon-cloudwatch
  ]
  metadata {
    name = "fluent-bit-role"
  }
  rule {
    non_resource_urls = ["/metrics"]
    verbs      = ["get"]
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods", "pods/logs", "nodes", "nodes/proxy"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "fluent-bit-role-binding" {
  depends_on = [
    kubernetes_namespace.amazon-cloudwatch
  ]
  metadata {
    name = "fluent-bit-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "fluent-bit-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "fluent-bit"
    namespace = "amazon-cloudwatch"
  }

}

resource "kubernetes_config_map" "fluent-bit-config" {
  depends_on = [
    kubernetes_namespace.amazon-cloudwatch
  ]
  metadata {
    name      = "fluent-bit-config"
    namespace = "amazon-cloudwatch"
    labels = {
      k8s-app = "fluent-bit"
    }
  }

  data = {
    "fluent-bit.conf"      = "${file("${path.module}/values/fluent-bit.conf")}"
    "application-log.conf" = "${file("${path.module}/values/application-log.conf")}"
    "dataplane-log.conf"   = "${file("${path.module}/values/dataplane-log.conf")}"
    "host-log.conf"        = "${file("${path.module}/values/host-log.conf")}"
    "parsers.conf"        = "${file("${path.module}/values/parsers.conf")}"
  }

}

resource "kubernetes_daemonset" "example" {
  depends_on = [
    kubernetes_namespace.amazon-cloudwatch
  ]
  metadata {
    name      = "fluent-bit"
    namespace = "amazon-cloudwatch"
    labels = {
      k8s-app                         = "fluent-bit"
      version                         = "v1"
      "kubernetes.io/cluster-service" = "true"
    }
  }

  spec {
    selector {
      match_labels = {
        k8s-app = "fluent-bit"
      }
    }

    template {
      metadata {
        labels = {
          k8s-app                         = "fluent-bit"
          version                         = "v1"
          "kubernetes.io/cluster-service" = "true"
        }
      }

      spec {
        container {
          image             = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable"
          name              = "fluent-bit"
          image_pull_policy = "Always"
          env {
            name = "AWS_REGION"
            value_from {
              config_map_key_ref {
                name = "fluent-bit-cluster-info"
                key  = "logs.region"
              }
            }
          }
          env {
            name = "CLUSTER_NAME"
            value_from {
              config_map_key_ref {
                name = "fluent-bit-cluster-info"
                key  = "cluster.name"
              }
            }
          }
          env {
            name = "HTTP_SERVER"
            value_from {
              config_map_key_ref {
                name = "fluent-bit-cluster-info"
                key  = "http.server"
              }
            }
          }
          env {
            name = "HTTP_PORT"
            value_from {
              config_map_key_ref {
                name = "fluent-bit-cluster-info"
                key  = "http.port"
              }
            }
          }
          env {
            name = "READ_FROM_HEAD"
            value_from {
              config_map_key_ref {
                name = "fluent-bit-cluster-info"
                key  = "read.head"
              }
            }
          }
          env {
            name = "READ_FROM_TAIL"
            value_from {
              config_map_key_ref {
                name = "fluent-bit-cluster-info"
                key  = "read.tail"
              }
            }
          }
          env {
            name = "HOST_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name = "HOSTNAME"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "metadata.name"
              }
            }
          }
          env {
            name  = "CI_VERSION"
            value = "k8s/1.3.10"
          }

          resources {
            limits = {
              memory = "200Mi"
            }
            requests = {
              cpu    = "500m"
              memory = "100Mi"
            }
          }

          volume_mount {
            name       = "fluentbitstate"
            mount_path = "/var/fluent-bit/state"
          }
          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
            read_only  = true
          }
          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }
          volume_mount {
            name       = "fluent-bit-config"
            mount_path = "/fluent-bit/etc/"
          }
          volume_mount {
            name       = "runlogjournal"
            mount_path = "/run/log/journal"
            read_only  = true
          }
          volume_mount {
            name       = "dmesg"
            mount_path = "/var/log/dmesg"
            read_only  = true
          }

        }
        termination_grace_period_seconds = 10
        host_network                     = true
        dns_policy                       = "ClusterFirstWithHostNet"
        volume {
          name = "fluentbitstate"
          host_path {
            path = "/var/fluent-bit/state"
          }
        }
        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }
        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }

        volume {
          name = "fluent-bit-config"
          config_map {
            name = "fluent-bit-config"
          }
        }

        volume {
          name = "runlogjournal"
          host_path {
            path = "/run/log/journal"
          }
        }

        volume {
          name = "dmesg"
          host_path {
            path = "/var/log/dmesg"
          }
        }

        service_account_name = "fluent-bit"
        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"

        }
        toleration {
          operator = "Exists"
          effect   = "NoExecute"

        }
        toleration {
          operator = "Exists"
          effect   = "NoSchedule"

        }

      }
    }
  }
}

