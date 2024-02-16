provider "aws" {
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = "http://localstack.default.svc.cluster.local:4566"
    cloudformation = "http://localstack.default.svc.cluster.local:4566"
    cloudwatch     = "http://localstack.default.svc.cluster.local:4566"
    dynamodb       = "http://localstack.default.svc.cluster.local:4566"
    ec2            = "http://localstack.default.svc.cluster.local:4566"
    es             = "http://localstack.default.svc.cluster.local:4566"
    elasticache    = "http://localstack.default.svc.cluster.local:4566"
    firehose       = "http://localstack.default.svc.cluster.local:4566"
    iam            = "http://localstack.default.svc.cluster.local:4566"
    kinesis        = "http://localstack.default.svc.cluster.local:4566"
    lambda         = "http://localstack.default.svc.cluster.local:4566"
    rds            = "http://localstack.default.svc.cluster.local:4566"
    redshift       = "http://localstack.default.svc.cluster.local:4566"
    route53        = "http://localstack.default.svc.cluster.local:4566"
    s3             = "http://localstack.default.svc.cluster.local:4566"
    secretsmanager = "http://localstack.default.svc.cluster.local:4566"
    ses            = "http://localstack.default.svc.cluster.local:4566"
    sns            = "http://localstack.default.svc.cluster.local:4566"
    sqs            = "http://localstack.default.svc.cluster.local:4566"
    ssm            = "http://localstack.default.svc.cluster.local:4566"
    stepfunctions  = "http://localstack.default.svc.cluster.local:4566"
    sts            = "http://localstack.default.svc.cluster.local:4566"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.2.0/24"
}

resource "aws_instance" "app_server_a" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.subnet_a.id
}

resource "aws_instance" "app_server_b" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.subnet_b.id
}

resource "aws_instance" "app_server_c" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.subnet_b.id
}
