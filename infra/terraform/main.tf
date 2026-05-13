resource "aws_ecs_cluster" "ecs_cluster" {
  name = "node-cluster"
}

resource "aws_security_group" "ecs_sg" {
    name = "ecs_security_group"
    description = "Security group for ECS tasks"

    vpc_id = var.vpc_id

    ingress {
        from_port   = 3000
        to_port     = 3000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_iam_role" "task_execution_role" {
    name = "ecsTaskExecutionRole"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Principal = {
                    Service = "ecs-tasks.amazonaws.com"
                },
                Action = "sts:AssumeRole"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
    role       = aws_iam_role.task_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "node_task" {
    family                   = "node-task"
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu                      = "256"
    memory                   = "512"

    execution_role_arn       = aws_iam_role.task_execution_role.arn

    container_definitions = jsonencode([
        {
            name      = "app",
            image     = var.image_url,
            essential = true,
            portMappings = [
                {
                    containerPort = 3000,
                    hostPort      = 3000,
                    protocol      = "tcp"
                }
            ]
        }
    ])
}

resource "aws_ecs_service" "node_service" {
    name = "node-service"
    cluster = aws_ecs_cluster.ecs_cluster.id
    task_definition = aws_ecs_task_definition.node_task.arn
    desired_count = 1
    launch_type = "FARGATE"

    network_configuration {
      subnets = var.subnets
      security_groups = [aws_security_group.ecs_sg.id]
      assign_public_ip = true
    }

    depends_on = [
        aws_iam_role_policy_attachment.ecs_task_execution_role_policy
     ]
}