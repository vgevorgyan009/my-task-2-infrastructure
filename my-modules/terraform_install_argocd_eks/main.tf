data "aws_eks_cluster" "this" {
  name       = var.eks_cluster_name
  depends_on = [var.eks_dependency]
}

data "aws_eks_cluster_auth" "this" {
  name       = var.eks_cluster_name
  depends_on = [var.eks_dependency]
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    token                  = data.aws_eks_cluster_auth.this.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm" # Official Chart Repo
  chart            = "argo-cd"                              # Official Chart Name
  namespace        = "argocd"
  version          = var.chart_version
  create_namespace = true
  values           = [file("${path.module}/argocd.yaml")]
}

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }

  set {
    name  = "controller.replicaCount"
    value = "3"
  }
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.29.0"
  namespace  = "kube-system"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.eks_cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true"
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "false"
  }

  set {
    name  = "podAnnotations.cluster-autoscaler\\.kubernetes\\.io/safe-to-evict"
    value = "\"false\""
  }

  set {
    name  = "image.tag"
    value = "v1.31.1"
  }
}

resource "helm_release" "external-secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
}
