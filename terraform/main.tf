provider "aws" {
  region = "us-east-1"
}

# S3 Bucket
resource "aws_s3_bucket" "ttt_bucket" {
  bucket = "ttt-bucket-266615"
  tags = {
    Name = "ttt-bucket-266615"
  }
}

# VPC
resource "aws_vpc" "a10_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name        = "a10-vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

# Subnet
resource "aws_subnet" "a10_subnet" {
  vpc_id            = aws_vpc.a10_vpc.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "a10-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "a10_igw" {
  vpc_id = aws_vpc.a10_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# Route Table
resource "aws_route_table" "a10_rt" {
  vpc_id = aws_vpc.a10_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.a10_igw.id
  }

  tags = {
    Name = "a10_rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "a10_rta" {
  subnet_id      = aws_subnet.a10_subnet.id
  route_table_id = aws_route_table.a10_rt.id
}

# Security Group
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.a10_vpc.id

  tags = {
    Name = "allow-ssh-http"
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_ssh_http.id
}

resource "aws_security_group_rule" "allow_http_https" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8081
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_ssh_http.id
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_ssh_http.id
}

# Cognito User Pool
resource "aws_cognito_user_pool" "a10_user_pool" {
  name = "a10_user_pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = false
  }

  auto_verified_attributes = ["email"]

  verification_message_template {
    email_message = "Your verification code is {####}"
    email_subject = "Verify your email"
    sms_message   = "Your verification code is {####}"
  }
}

resource "aws_cognito_user_pool_client" "a10_user_pool_client" {
  name                     = "a10_user_pool_client"
  user_pool_id             = aws_cognito_user_pool.a10_user_pool.id
  generate_secret          = false
  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "a10_user_pool_domain" {
  domain       = "tic-tac-toe-266615"
  user_pool_id = aws_cognito_user_pool.a10_user_pool.id
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "a10_instance_profile" {
  name = "LabRoleInstanceProfile2"
  role = "LabRole"
}

# DynamoDB Table
resource "aws_dynamodb_table" "ttt_game_table" {
  name         = "TicTacToeGame"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "GameId"

  attribute {
    name = "GameId"
    type = "S"
  }

  tags = {
    Name = "TicTacToeGame"
  }
}

resource "aws_dynamodb_table" "player_ranking_table" {
  name         = "PlayerRanking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PlayerId"

  attribute {
    name = "PlayerId"
    type = "S"
  }

  tags = {
    Name = "PlayerRanking"
  }
}

# EC2 Instance
resource "aws_instance" "a10_web_server" {
  ami                         = "ami-080e1f13689e07408"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.a10_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  iam_instance_profile        = aws_iam_instance_profile.a10_instance_profile.name
  user_data                   = <<-EOF
    #!/bin/bash
    apt update
    apt install -y docker docker-compose

    echo "export AWS_SDK_LOAD_CONFIG=1" >> /home/ubuntu/.bashrc
    source /home/ubuntu/.bashrc

    cd /home/ubuntu

    # Clone repository
    git clone https://github.com/pwr-cloudprogramming/a12-Arbuz0.git
    cd a12-Arbuz0
    cd app

    # Update cognito-config.js
    cat <<EOT > /home/ubuntu/a12-Arbuz0/app/frontend/src/js/cognito-config.js
    const COGNITO_USER_POOL_ID = '${aws_cognito_user_pool.a10_user_pool.id}';
    const COGNITO_CLIENT_ID = '${aws_cognito_user_pool_client.a10_user_pool_client.id}';
    const COGNITO_REGION = 'us-east-1';
    const S3_BUCKET_NAME = '${aws_s3_bucket.ttt_bucket.bucket}';
    EOT

    # Update config.js
    cat <<EOT > /home/ubuntu/a12-Arbuz0/app/frontend/src/js/config.js
    const apiGatewayUrl = '${aws_api_gateway_deployment.game_results_deployment.invoke_url}';
    EOT

    # Update application.properties
    cat <<EOT > /home/ubuntu/a12-Arbuz0/app/backend/src/main/resources/application.properties
    USER_POOL_ID=${aws_cognito_user_pool.a10_user_pool.id}
    USER_POOL_CLIENT_ID=${aws_cognito_user_pool_client.a10_user_pool_client.id}
    USER_POOL_DOMAIN=${aws_cognito_user_pool_domain.a10_user_pool_domain.domain}.auth.us-east-1.amazoncognito.com
    aws.region=us-east-1
    cloud.aws.region.static=us-east-1
    cloud.aws.s3.bucket=${aws_s3_bucket.ttt_bucket.bucket}
    dynamodb.table.name=${aws_dynamodb_table.ttt_game_table.name}
    EOT

    # Start the Docker containers
    docker-compose up -d
  EOF
  user_data_replace_on_change = true
  tags = {
    Name = "a10-TicTacToe"
  }
}

# Lambda Function
resource "aws_lambda_function" "update_ranking" {
  filename         = "lambda_update_ranking.zip"
  function_name    = "UpdateRanking"
  role             = "arn:aws:iam::730335575456:role/LabRole"
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("lambda_update_ranking.zip")
  runtime          = "python3.8"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.ttt_game_table.name
    }
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "game_results_api" {
  name = "GameResultsAPI"
}

resource "aws_api_gateway_resource" "results_resource" {
  rest_api_id = aws_api_gateway_rest_api.game_results_api.id
  parent_id   = aws_api_gateway_rest_api.game_results_api.root_resource_id
  path_part   = "results"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.game_results_api.id
  resource_id   = aws_api_gateway_resource.results_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.game_results_api.id
  resource_id = aws_api_gateway_resource.results_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.update_ranking.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_ranking.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.game_results_api.execution_arn}/*/*"
}

# Define the OPTIONS method for CORS preflight
resource "aws_api_gateway_method" "options_method" {
  rest_api_id = aws_api_gateway_rest_api.game_results_api.id
  resource_id = aws_api_gateway_resource.results_resource.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.game_results_api.id
  resource_id = aws_api_gateway_resource.results_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  integration_http_method = "OPTIONS"
}

resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.game_results_api.id
  resource_id = aws_api_gateway_resource.results_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.game_results_api.id
  resource_id = aws_api_gateway_resource.results_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = aws_api_gateway_method_response.options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  response_templates = {
    "application/json" = ""
  }
}

# Update the POST method response to include CORS headers
resource "aws_api_gateway_method_response" "post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.game_results_api.id
  resource_id = aws_api_gateway_resource.results_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.game_results_api.id
  resource_id = aws_api_gateway_resource.results_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = aws_api_gateway_method_response.post_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST, OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.post_method,
    aws_api_gateway_integration.lambda_integration
  ]
}

# Output the API URL
output "api_url" {
  value = "${aws_api_gateway_deployment.game_results_deployment.invoke_url}/results"
}

resource "aws_api_gateway_deployment" "game_results_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration_response.post_integration_response
  ]
  rest_api_id = aws_api_gateway_rest_api.game_results_api.id
  stage_name  = "prod"
}

output "app_url" {
  value = "http://${aws_instance.a10_web_server.public_ip}:8081"
}