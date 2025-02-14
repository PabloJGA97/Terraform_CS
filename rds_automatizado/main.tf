provider "aws" {
  region = var.aws_region
}

# Obtener la VPC y subnets por defecto
data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

# Crear RDS con el módulo de la comunidad 
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.1.0"

  identifier        = "my-rds"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  # el modulo habilita por defecto que la contraseña y usuario sean generados por AWS Secret Manager, para deshabilitarlo escribe manager_master_user_password = false
  manage_master_user_password = false
  db_name                     = var.db_name
  username                    = var.db_username
  password                    = var.db_password

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  subnet_ids             = data.aws_subnets.default_subnets.ids

  major_engine_version = "8.0"
  family               = "mysql8.0"
}

# Crear Security Group para RDS
# quizá añadir una outbound rule para que pueda enviar info, ya que ahora la base de datos solo puede ser consultada
resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-sg"
  description = "Permitir acceso MySQL desde la EC2"
  vpc_id      = data.aws_vpc.default_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default_vpc.cidr_block]
  }
}

# Crear Security Group para EC2
resource "aws_security_group" "ec2_sg" {
  # antes me ha saltado un error de incompatibilidad de caracteres ASCII2. Solo he quitado la tilde de "tráfico" y listo. La programación está pensada sobretodo en inglés y no suele esperar caracteres con tildes o 'ñ', así que es mejor evitarlos ya que el intérprete puede dar errores
  name_prefix = "ec2-sg"
  description = "Permitir trafico HTTP y SSH"
  vpc_id      = data.aws_vpc.default_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # aqui falta una regla de outbound para que la instancia tenga salida a internet y pueda actualizar y descargar programas con los comandos del user-data
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Crear la EC2 con el módulo de la comunidad
module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.1"

  name          = "wordpress-ec2"
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  associate_public_ip_address = var.public_ip
  subnet_id                   = data.aws_subnets.default_subnets.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]

  # usamos el template en un archivo.sh, como lo tenemos dentro de un directorio, pues ponemos la ruta
  # el valor de la variable la cogemos del output del modulo, que podemos encontrar en la documentacion del modulo en el terraform-registry.com
  # función split porque el output de terraform nos devuelve el endpoint con ":3306" al final y eso el wp-config ni el mysql no lo interpretan como un endpoint 
  # Además el root de la ruta no es la del sistema sino el de la carpeta de Terraform donde hacemos init, así que si los scripts de user-data están en la misma carpeta que el main.tf, pues solo indicamos el nombre del archivo       
  user_data  = templatefile("./templates/publica.sh", { rds_endpoint = module.rds.db_instance_endpoint })

  # esperará a que se cree el RDS para empezar a crearse el EC2
  depends_on = [module.rds]
}
