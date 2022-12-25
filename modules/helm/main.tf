resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  values           = [file("${path.module}/values/ingress-nginx.yaml")]
}


resource "helm_release" "amp" {
  name             = "prometheus-for-amp"
  namespace        = "prometheus"
  create_namespace = true
  chart            = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  values           = [file("${path.module}/values/amp.yaml")]

  set {
    name  = "serviceAccounts.server.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.amp_rolearn
  }

  set {
    name = "server.remoteWrite[0].url"
    value = "https://aps-workspaces.${var.region}.amazonaws.com/workspaces/${var.amp_workspaceid}/api/v1/remote_write"
  }
  set {
    name = "server.remoteWrite[0].sigv4.region"
    value = var.region
  }
}
