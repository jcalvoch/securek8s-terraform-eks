

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "app" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-${var.environment}-app-vpc"
  }
}


resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app.id
  tags = {
    Name = "${var.project_name}-${var.environment}-app-vpc-igw"
  }
}


resource "aws_subnet" "app_publicsubnet1" {
  vpc_id            = aws_vpc.app.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
  tags = {
    Name = "${var.project_name}-${var.environment}-app-vpc-pubsubnet-1"
  }
}


resource "aws_eip" "app_natgw1" {
  vpc = true
}


resource "aws_nat_gateway" "app_natgw1" {
  allocation_id = aws_eip.app_natgw1.id
  subnet_id     = aws_subnet.app_publicsubnet1.id

  tags = {
    Name = "${var.project_name}-${var.environment}-app-vpc-ngw1"
  }

  depends_on = [aws_internet_gateway.app_igw]
}


resource "aws_subnet" "app_privatesubnet1" {
  vpc_id            = aws_vpc.app.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2)
  tags = {
    Name = "${var.project_name}-${var.environment}-app-vpc-privsubnet-1"
  }
}


resource "aws_subnet" "app_publicsubnet2" {
  vpc_id            = aws_vpc.app.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 3)
  tags = {
    Name = "${var.project_name}-${var.environment}-app-vpc-pubsubnet-2"
  }
}


resource "aws_eip" "app_natgw2" {
  vpc = true
}


resource "aws_nat_gateway" "app_natgw2" {
  allocation_id = aws_eip.app_natgw2.id
  subnet_id     = aws_subnet.app_publicsubnet2.id

  tags = {
    Name = "${var.project_name}-${var.environment}-app-vpc-ngw2"
  }

  depends_on = [aws_internet_gateway.app_igw]
}


resource "aws_subnet" "app_privatesubnet2" {
  vpc_id            = aws_vpc.app.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 4)
  tags = {
    Name = "${var.project_name}-${var.environment}-app-vpc-privsubnet-2"
  }
}


resource "aws_route_table" "app_private1" {
  vpc_id = aws_vpc.app.id


  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app_natgw1.id
  }


  tags = {
    Name = "${var.project_name}-${var.environment}-app-vpc-pubrt"
  }

}


resource "aws_route_table_association" "app_private1" {
  subnet_id      = aws_subnet.app_privatesubnet1.id
  route_table_id = aws_route_table.app_private1.id
}


resource "aws_route_table" "app_private2" {
  vpc_id = aws_vpc.app.id


  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app_natgw2.id
  }


  tags = {
    Name = "${var.project_name}-${var.environment}-app-vpc-pubrt"
  }
}


resource "aws_route_table_association" "app_private2" {
  subnet_id      = aws_subnet.app_privatesubnet2.id
  route_table_id = aws_route_table.app_private2.id
}



resource "aws_default_route_table" "app_public" {
  default_route_table_id = aws_vpc.app.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-vpc-pubrt"
  }
}


resource "aws_security_group" "vpcendpoints" {
  name        = "vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.app.id

  ingress {
    description = "Permitir TLS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [cidrsubnet(var.vpc_cidr, 8, 2), cidrsubnet(var.vpc_cidr, 8, 4)]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-sgendpoints"
  }
}



resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = aws_vpc.app.id
  service_name      = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpcendpoints.id
  ]

  subnet_ids = [aws_subnet.app_privatesubnet1.id, aws_subnet.app_privatesubnet2.id]

  private_dns_enabled = true


  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-endpointec2"
  }
}


resource "aws_vpc_endpoint" "ecrapi" {
  vpc_id            = aws_vpc.app.id
  service_name      = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpcendpoints.id
  ]

  subnet_ids = [aws_subnet.app_privatesubnet1.id, aws_subnet.app_privatesubnet2.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-endpointapi"
  }
}


resource "aws_vpc_endpoint" "sts" {
  vpc_id            = aws_vpc.app.id
  service_name      = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpcendpoints.id
  ]

  subnet_ids = [aws_subnet.app_privatesubnet1.id, aws_subnet.app_privatesubnet2.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-endpointsts"
  }
}


resource "aws_vpc_endpoint" "logs" {
  vpc_id            = aws_vpc.app.id
  service_name      = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpcendpoints.id
  ]

  subnet_ids = [aws_subnet.app_privatesubnet1.id, aws_subnet.app_privatesubnet2.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-endpointlogs"
  }
}


resource "aws_vpc_endpoint" "dkr" {
  vpc_id            = aws_vpc.app.id
  service_name      = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpcendpoints.id
  ]

  subnet_ids = [aws_subnet.app_privatesubnet1.id, aws_subnet.app_privatesubnet2.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-endpointdkr"
  }
}


resource "aws_vpc_endpoint" "kms" {
  vpc_id            = aws_vpc.app.id
  service_name      = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpcendpoints.id
  ]

  subnet_ids = [aws_subnet.app_privatesubnet1.id, aws_subnet.app_privatesubnet2.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-endpointkms"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.app.id
  route_table_ids = [aws_route_table.app_private1.id, aws_route_table.app_private2.id]
  service_name    = "com.amazonaws.${var.region}.s3"

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-endpoints3"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id          = aws_vpc.app.id
  route_table_ids = [aws_route_table.app_private1.id, aws_route_table.app_private2.id]
  service_name    = "com.amazonaws.${var.region}.dynamodb"

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-endpointdynamodb"
  }
}




# K8s cluster security group
# By default this is not secured. Change this according to your requirements

resource "aws_security_group" "eks" {
  name        = "eks-cluster"
  description = "Security group assigned to Kubernetes cluster ${var.project_name}-${var.environment}-eks-cluster"
  vpc_id      = aws_vpc.app.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-sgcluster"
  }
}
