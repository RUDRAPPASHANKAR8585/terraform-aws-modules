resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster ${var.cluster_name}"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-cluster-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "cluster_from_node" {
  security_group_id = aws_security_group.cluster.id

  referenced_security_group_id = aws_security_group.node.id
  ip_protocol                  = "-1"

  description = "Allow traffic from EKS worker nodes to cluster security group"
}

resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes ${var.cluster_name}"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-node-sg"
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "node_all" {
  security_group_id = aws_security_group.node.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow outbound traffic from EKS worker nodes"
}

resource "aws_vpc_security_group_ingress_rule" "node_from_cluster" {
  security_group_id = aws_security_group.node.id

  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "-1"

  description = "Allow traffic from EKS cluster security group to worker nodes"
}

