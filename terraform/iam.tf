# 1. Definición del Rol IAM para la instancia EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  # Política que permite a los servicios EC2 asumir este rol
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# 2. Adjuntar política para lectura de ECR (AmazonEC2ContainerRegistryReadOnly)
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 3. Adjuntar política para acceso por AWS SSM Session Manager (AmazonSSMManagedInstanceCore)
# Esto es una buena práctica ya que la EC2 está en una subred privada sin puertos de SSH (22) abiertos
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 4. Crear el Perfil de Instancia de IAM para asignárselo a la EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
