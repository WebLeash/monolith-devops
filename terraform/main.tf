# EKS Cluster
resource "aws_eks_cluster" "eks-demo-cluster-01" {
  name     = var.name != "" ? "${var.name}-monolith" : "monolith"
  version  = "1.28"
  role_arn = aws_iam_role.eks-demo-cluster-admin-role-01.arn
  vpc_config {
    subnet_ids = [
      aws_subnet.eks-demo-public-01.id,
      aws_subnet.eks-demo-public-02.id
    ]
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks-demo-cluster-01-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-demo-cluster-01-AmazonEKSVPCResourceController
  ]
  tags = {
    demo = "eks"
  }
}

# IAM Policy Document for Cluster Role
data "aws_iam_policy_document" "eks-demo-cluster-admin-role-policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks-demo-cluster-admin-role-01" {
  name               = "eks-demo-cluster-admin-role-01"
  assume_role_policy = data.aws_iam_policy_document.eks-demo-cluster-admin-role-policy.json
}

# Attach Policies to EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks-demo-cluster-01-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-demo-cluster-admin-role-01.name
}

resource "aws_iam_role_policy_attachment" "eks-demo-cluster-01-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-demo-cluster-admin-role-01.name
}

# IAM Role for Fargate Profile
resource "aws_iam_role" "eks-fargate-demo-profile-role-01" {
  name = "eks-fargate-demo-profile-role-01"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-demo-fargate-profile-01" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks-fargate-demo-profile-role-01.name
}

# IAM Roles and Policies for Node Group
resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_readonly_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}


# Additional Permissions for Node Group
resource "aws_iam_role_policy" "additional_permissions" {
  role = aws_iam_role.eks_node_group_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeAvailabilityZones",
          "elasticloadbalancing:DescribeLoadBalancers"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.eks-demo-cluster-01.name
  node_group_name = "example-node-group"
  node_role_arn   = aws_iam_role.eks-node-role.arn
  subnet_ids      = [aws_subnet.eks-demo-public-01.id, aws_subnet.eks-demo-public-02.id]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_eks_cluster.eks-demo-cluster-01
  ]
}

resource "aws_iam_role" "eks-node-role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks-node-policy" {
  role       = aws_iam_role.eks-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks-cni-policy" {
  role       = aws_iam_role.eks-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks-registry-policy" {
  role       = aws_iam_role.eks-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}




# Addons
resource "aws_eks_addon" "eks-demo-addon-coredns" {
  cluster_name                = aws_eks_cluster.eks-demo-cluster-01.name
  addon_name                  = "coredns"
  addon_version               = "v1.10.1-eksbuild.4"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "eks-demo-addon-kube-proxy" {
  cluster_name                = aws_eks_cluster.eks-demo-cluster-01.name
  addon_name                  = "kube-proxy"
  addon_version               = "v1.28.2-eksbuild.2"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "eks-demo-addon-vpc-cni" {
  cluster_name                = aws_eks_cluster.eks-demo-cluster-01.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.15.1-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
}


# VPC-01
resource "aws_vpc" "eks-demo-vpc-01" {
  cidr_block = "10.0.0.0/16"

  # Must be enabled for EFS
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-demo-vpc-01"
  }
}

# Public Subnet in AZ 1
resource "aws_subnet" "eks-demo-public-01" {
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  vpc_id                  = aws_vpc.eks-demo-vpc-01.id
  map_public_ip_on_launch = true
  tags = {
    Name                     = "eks-demo-public-01"
    "kubernetes.io/role/elb" = "1"

  }
}

# Private Subnet in AZ 1
resource "aws_subnet" "eks-demo-private-01" {
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2a"
  vpc_id                  = aws_vpc.eks-demo-vpc-01.id
  map_public_ip_on_launch = false
  tags = {
    Name                              = "eks-demo-private-01"
    "kubernetes.io/role/internal-elb" = "1"

  }
}

# Public Subnet in AZ 2
resource "aws_subnet" "eks-demo-public-02" {
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2b"
  vpc_id                  = aws_vpc.eks-demo-vpc-01.id
  map_public_ip_on_launch = true
  tags = {
    Name                     = "eks-demo-public-02"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private Subnet in AZ 2
resource "aws_subnet" "eks-demo-private-02" {
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-west-2b"
  vpc_id                  = aws_vpc.eks-demo-vpc-01.id
  map_public_ip_on_launch = false
  tags = {
    Name                              = "eks-demo-private-02"
    "kubernetes.io/role/internal-elb" = "1"

  }
}

# EIP
resource "aws_eip" "demo-eip-01" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.eks-demo-internet-gateway-01]
  tags = {
    Name = "demo-eip-01"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "eks-demo-internet-gateway-01" {
  vpc_id = aws_vpc.eks-demo-vpc-01.id
  tags = {
    Name = "eks-demo-internet-gateway"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "eks-demo-internet-nat" {
  allocation_id = aws_eip.demo-eip-01.id
  subnet_id     = aws_subnet.eks-demo-public-01.id

  tags = {
    Name = "eks-demo-net-gateway"
  }

  depends_on = [aws_internet_gateway.eks-demo-internet-gateway-01]
}

# Public Route Table
resource "aws_route_table" "eks-demo-public" {
  vpc_id = aws_vpc.eks-demo-vpc-01.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-demo-internet-gateway-01.id
  }

  tags = {
    Name = "eks-demo-public"
  }
}

# Private Route Table
resource "aws_route_table" "eks-demo-private" {
  vpc_id = aws_vpc.eks-demo-vpc-01.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks-demo-internet-nat.id
  }

  tags = {
    Name = "eks-demo-private"
  }
}

# Route Table Associations
resource "aws_route_table_association" "private-eu-west-2a" {
  subnet_id      = aws_subnet.eks-demo-private-01.id
  route_table_id = aws_route_table.eks-demo-private.id
}

resource "aws_route_table_association" "private-eu-west-2b" {
  subnet_id      = aws_subnet.eks-demo-private-02.id
  route_table_id = aws_route_table.eks-demo-private.id
}

resource "aws_route_table_association" "public-eu-west-2a" {
  subnet_id      = aws_subnet.eks-demo-public-01.id
  route_table_id = aws_route_table.eks-demo-public.id
}

resource "aws_route_table_association" "public-eu-west-2b" {
  subnet_id      = aws_subnet.eks-demo-public-02.id
  route_table_id = aws_route_table.eks-demo-public.id
}

resource "aws_security_group" "worker_nodes" {
  name        = "worker-nodes-sg"
  description = "Security group for all worker nodes"
  vpc_id      = aws_vpc.eks-demo-vpc-01.id

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "worker-nodes-sg"
  }

  depends_on = [aws_vpc.eks-demo-vpc-01]
}

