provider "kubectl" {
  apply_retry_count      = 15
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    command     = "aws"
  }
}

data "kubectl_path_documents" "namespaces" {
  pattern = "./k8s_manifests/namespaces/*.yaml"
}

resource "kubectl_manifest" "my_namespaces" {
  count      = length(data.kubectl_path_documents.namespaces.documents)
  yaml_body  = element(data.kubectl_path_documents.namespaces.documents, count.index)
  depends_on = [module.my_eks]
}

################################
#Apply .yaml manifests from ./k8s_manifests/controllers_prerequisites/

data "kubectl_path_documents" "controllers_prerequisites" {
  pattern = "./k8s_manifests/controllers_prerequisites/*.yaml"
}

resource "kubectl_manifest" "my_controllers_prerequisites" {
  count     = length(data.kubectl_path_documents.controllers_prerequisites.documents)
  yaml_body = element(data.kubectl_path_documents.controllers_prerequisites.documents, count.index)

  depends_on = [kubectl_manifest.my_namespaces]
}

################################
#Apply .yaml manifests from ./k8s_manifests/ingress/

data "kubectl_path_documents" "ingress" {
  pattern = "./k8s_manifests/ingress/*.yaml"
}

resource "kubectl_manifest" "my_ingress" {
  count     = length(data.kubectl_path_documents.ingress.documents)
  yaml_body = element(data.kubectl_path_documents.ingress.documents, count.index)

  depends_on = [helm_release.helm-traefik, helm_release.helm-aws-ingress, helm_release.helm-ext-dns]
}




