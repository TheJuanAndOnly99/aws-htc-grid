# Copyright 2023 Amazon.com, Inc. or its affiliates. 
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/


#KEDA role & permissions
module "keda_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-eks-role"
  version = "~> 5.0"

  role_name = "role_keda_${local.suffix}"
  role_policy_arns = {
    keda_permissions = aws_iam_policy.keda_permissions.arn
  }

  cluster_service_accounts = {
    (var.cluster_name) = ["keda:keda-operator"]
  }

  depends_on = [
    # Wait for EKS to be deployed first
    module.eks,
  ]
}


resource "aws_iam_policy" "keda_permissions" {
  name        = "keda_permissions_policy_${local.suffix}"
  path        = "/"
  description = "IAM policy for KEDA Permissions"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}


#Lambda Drainer EKS Access
resource "kubernetes_cluster_role" "lambda_cluster_access" {
  metadata {
    name = "lambda-cluster-access"
  }

  rule {
    verbs      = ["create", "list", "patch"]
    api_groups = [""]
    resources  = ["pods", "pods/eviction", "nodes"]
  }

  depends_on = [
    module.eks,
  ]
}


resource "kubernetes_cluster_role_binding" "lambda_user_cluster_role_binding" {
  metadata {
    name = "lambda-user-cluster-role-binding"
  }

  subject {
    kind = "User"
    name = "lambda"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "lambda-cluster-access"
  }

  depends_on = [
    module.eks,
  ]
}
