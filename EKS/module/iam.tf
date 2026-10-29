data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  count = local.windows_nodes_enabled ? 1 : 0

  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

data "tls_certificate" "oidc" {
  count = var.enable_irsa ? 1 : 0

  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  count = var.enable_irsa ? 1 : 0

  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.oidc[0].certificates[0].sha1_fingerprint
  ]

  tags = local.common_tags
}

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  count = contains(keys(var.addons), "ebs_csi") && var.enable_irsa ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.this[0].arn
      ]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    condition {
      test = "StringEquals"
      variable = "${replace(
        aws_eks_cluster.this.identity[0].oidc[0].issuer,
        "https://",
        ""
      )}:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test = "StringEquals"
      variable = "${replace(
        aws_eks_cluster.this.identity[0].oidc[0].issuer,
        "https://",
        ""
      )}:sub"

      values = [
        "system:serviceaccount:kube-system:ebs-csi-controller-sa"
      ]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  count = contains(keys(var.addons), "ebs_csi") && var.enable_irsa ? 1 : 0

  name = "${var.cluster_name}-ebs-csi-role"

  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count = contains(keys(var.addons), "ebs_csi") && var.enable_irsa ? 1 : 0

  role = aws_iam_role.ebs_csi[0].name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "aws_iam_policy_document" "efs_csi_assume_role" {
  count = contains(keys(var.addons), "efs_csi") && var.enable_irsa ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.this[0].arn
      ]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.this[0].url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.this[0].url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:kube-system:efs-csi-controller-sa"
      ]
    }
  }
}

resource "aws_iam_role" "efs_csi" {
  count = contains(keys(var.addons), "efs_csi") && var.enable_irsa ? 1 : 0

  name = "${var.cluster_name}-efs-csi-role"

  assume_role_policy = data.aws_iam_policy_document.efs_csi_assume_role[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "efs_csi" {
  count = contains(keys(var.addons), "efs_csi") && var.enable_irsa ? 1 : 0

  role = aws_iam_role.efs_csi[0].name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}