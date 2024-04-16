// [1] security group for rds

resource "aws_security_group" "rds_sg" {

  name   = "${var.name_prefix}-rds-sg"
  vpc_id = var.vpc.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "for debug only, login mysql from local machine, should be removed later"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }


  ingress {
    cidr_blocks = [var.vpc.cidr_block]
    description = "only allow traffic from this vpc"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }

  /*
  ingress {
    security_groups = [ aws_security_group.ecs_sg.id ]
    description = "only allow traffic from instances belong to ecs security group"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
  }
  */

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
  }

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }

}

// [2] database subnet group

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.subnets.*.id
  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }
}


resource "aws_db_instance" "rds" {

  identifier = "${var.name_prefix}-rds"
  allocated_storage = 10
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t3.micro"
  username = "foo"
  password = "foobarbaz"
  parameter_group_name = "default.mysql5.7"

  publicly_accessible = true
  skip_final_snapshot = true

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  delete_automated_backups = false

  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "${var.name_prefix}-rds"
  }
}
