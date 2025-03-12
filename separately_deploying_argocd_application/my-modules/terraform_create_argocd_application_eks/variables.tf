variable "eks_cluster_name" {
  description = "EKS Cluster name to deploy ArgoCD Application"
  type        = string
}

variable "git_source_repoURL" {
  description = "GitSource repoURL to Track and deploy to EKS by ArgoCD Application"
  type        = string
}

variable "git_source_path" {
  description = "GitSource Path in Git Repository to Track and deploy to EKS by ArgoCD Application"
  type        = string
  default     = ""
}

variable "git_source_targetRevision" {
  description = "GitSource HEAD or Branch to Track and deploy to EKS by ArgoCD Application"
  type        = string
  default     = "HEAD"
}

/*
variable "eks_dependency" {
  description = "Dependency on the EKS module to ensure ArgoCD waits for EKS to be ready"
  type        = any
}

variable "argocd_dependency" {
  description = "Dependency on the EKS module to ensure ArgoCD waits for EKS to be ready"
  type        = any
}
*/
