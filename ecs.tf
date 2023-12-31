
resource "aws_ecs_cluster" "testcluster" {
  name = "johntestecs"
}

resource "aws_ecs_cluster_capacity_providers" "testcluster" {
  cluster_name = aws_ecs_cluster.testcluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
