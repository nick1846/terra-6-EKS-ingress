provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
      command     = "aws"
    }
  }
}


#Install AWS load balancer contriller with helm chart

resource "helm_release" "helm-aws-ingress" {
  name       = "helm-aws-ingress"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version    = "1.1.5"
  namespace  = "ingress-controllers"
  depends_on = [kubectl_manifest.my_controllers_prerequisites]

  set {
    name  = "autoDiscoverAwsRegion"
    value = "true"
  }
  set {
    name  = "autoDiscoverAwsVpcID"
    value = "true"
  }
  set {
    name  = "clusterName"
    value = local.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-ingress-controller"
  }
}

#Install External DNS controller with helm

resource "helm_release" "helm-ext-dns" {
  name       = "helm-ext-dns"
  chart      = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "4.12.3"
  namespace  = "ingress-controllers"
  depends_on = [kubectl_manifest.my_controllers_prerequisites]

  set {
    name  = "provider"
    value = "aws"
  }
  set {
    name  = "aws.region"
    value = "us-east-2"
  }
  set {
    name  = "aws.zoneType"
    value = "public"
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }
  set {
    name  = "domainFilters[0]"
    value = "justpipeline.com"
  }
  set {
    name  = "podSecurityContext.fsGroup"
    value = "65534"
  }
  set {
    name  = "podSecurityContext.runAsUser"
    value = "0"
  }
  set {
    name  = "registry"
    value = "noop"
  }
}


#Install Traefik controller with helm

resource "helm_release" "helm-traefik" {
  name       = "helm-traefik"
  chart      = "traefik"
  repository = "https://helm.traefik.io/traefik"
  version    = "9.19.1"
  namespace  = "ingress-controllers"
  values     = [file("./helm_values/traefik/values.yaml")]
  depends_on = [kubectl_manifest.my_namespaces]
}




