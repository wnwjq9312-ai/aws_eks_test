
# RDS SG
module "RDS_SG" {
  source          = "terraform-aws-modules/security-group/aws"
  version         = "5.1.0"
  name            = "RDS_SG"
  description     = "DB Port Allow"
  vpc_id          = data.terraform_remote_state.vpc_remote_data.outputs.vpc_id
  use_name_prefix = "false"

  ingress_with_cidr_blocks = [
    {
      from_port   = var.db_port
      to_port     = var.db_port
      protocol    = local.tcp_protocol
      description = "DB Port Allow"
      cidr_blocks = data.terraform_remote_state.vpc_remote_data.outputs.private_subnets[0]
    },
    {
      from_port   = var.db_port
      to_port     = var.db_port
      protocol    = local.tcp_protocol
      description = "DB Port Allow"
      cidr_blocks = data.terraform_remote_state.vpc_remote_data.outputs.private_subnets[1]
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = local.any_port
      to_port     = local.any_port
      protocol    = local.any_protocol
      cidr_blocks = local.all_network
    }
  ]
}

module "rds" {
  source                              = "terraform-aws-modules/rds/aws"
  version                             = "6.1.1"
  identifier                          = "eks-rds"
  engine                              = "mysql"
  engine_version                      = "5.7"
  instance_class                      = "db.t3.micro"
  allocated_storage                   = 5
  multi_az                            = false
  iam_database_authentication_enabled = true
  manage_master_user_password         = false
  skip_final_snapshot                 = true
  family                              = "mysql5.7"

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  major_engine_version = "5.7"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  port                 = var.db_port

  # DB subnet group & DB Security-Group
  db_subnet_group_name   = data.terraform_remote_state.vpc_remote_data.outputs.database_subnet_group
  subnet_ids             = data.terraform_remote_state.vpc_remote_data.outputs.database_subnets
  vpc_security_group_ids = [module.RDS_SG.security_group_id]
}
