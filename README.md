# projeto-eks

A ideia do projeto será utilizar o EKS disponibilizado pela AWS para implementação de uma aplicação web que utiliza clusters Kubernetes. Nesse caso a função do Elastic Kubernetes Service será gerenciar a aplicação.

Para realizar essa tarefa serão utilizadas algumas tecnologias, como:
1. EKS
2. Docker
3. Aplicação Web
4. Load Balancer


	O Docker é útil nessa situação porque permite criar uma imagem de contêiner autocontido que inclui tudo o que é necessário para executar sua aplicação web, incluindo o código, as dependências e qualquer outro software necessário. Ao empacotar sua aplicação e suas dependências em um contêiner do Docker, você pode garantir que sua aplicação seja executada de maneira consistente e previsível em diferentes ambientes, sem problemas de compatibilidade ou conflitos com outro software instalado no sistema host.
	
	Para um caso simples como o de implantar uma aplicação web em um container Docker e implantá-la no EKS usando Kubernetes e um LoadBalancer, uma opção seria utilizar um aplicativo web em Python, como o Flask.
	
	No caso da implantação de uma aplicação web simples usando um cluster Kubernetes gerenciado pelo Amazon EKS, utilizar um serviço Load Balancer é importante para melhorar a disponibilidade e a escalabilidade da aplicação. Quando a aplicação é implantada em um ambiente de produção, ela geralmente é executada em vários contêineres que são distribuídos em diferentes nós do cluster Kubernetes. Sem um Load Balancer, as solicitações de rede dos usuários finais podem ser direcionadas para um único contêiner, o que pode sobrecarregá-lo e reduzir a disponibilidade da aplicação. O Elastic Load Balancing (ELB) é um serviço gerenciado que distribui automaticamente o tráfego de entrada entre vários destinos, como instâncias EC2, contêineres do Amazon ECS ou serviços do Amazon EKS, para aumentar a escalabilidade e a disponibilidade de aplicativos.
	
	Para adicionar algumas features de segurança também há a possibilidade de adicionar:
1. WAF
2. GuardDuty
3. CloudWatch

## Roteiro Para Implementação de uma Aplicação web com EKS

Para conseguir executar o roteiro, além de coisas específicas de AWS e kubernetes, serão necessários:
1. Python - https://www.python.org/downloads/ 
2. Docker - Windows: https://docs.docker.com/desktop/install/windows-install/ 
			 - Ubuntu: https://docs.docker.com/engine/install/ubuntu/ 

# Instalando e configurando o AWS CLI, Terraform e Kubectl:
1. Instale o Terraform: https://learn.hashicorp.com/tutorials/terraform/install-cli 
2. Instale e Configure o AWS CLI: https://aws.amazon.com/cli/ 
### Abra o terminal de comando e execute o comando:
**aws configure**
1. Quando solicitado, insira suas credenciais da AWS - Access Key ID e Secret Access Key. Você pode encontrar essas informações no Console AWS em Credenciais de segurança, ou consultando o administrador da sua conta AWS. Além disso, será necessário o local, que nesse caso é o us-east-1. Na última alternativa pode somente pressionar o ENTER.
2. Instale o Kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl/ 

### Criando uma aplicação web simples
Nesse caso usaremos flask para criar essa aplicação

Crie um novo diretório para o projeto

Dentro deste diretório crie um arquivo chamado app.py com o código abaixo(para rodar certifique-se de que tem a biblioteca Flask instalada, caso não tenha instale com PIP):

```
from flask import Flask
app = Flask(__name__)


@app.route('/')
def hello():
    return "Hello World!"


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
```

Crie um arquivo Dockerfile no mesmo diretório onde foi criado o app.py, com  seguinte código:
```
FROM python:3.8-slim


WORKDIR /app


COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


COPY . .


CMD ["python", "app.py"]
```

Crie um arquivo requirements.txt que vai conter todas as bibliotecas necessárias para a execução do web app no container. Para o caso dessa aplicação simples, a única biblioteca necessária será o Flask.
``Flask==2.1.1``

Em seguida, abra o Docker, se estiver no Windows precisa somente abrir o Docker Desktop.

Com o Docker aberto, abra o Prompt de Comando na pasta do projeto e execute os seguintes comandos:


``docker build -t my-web-app .``

``docker run -p 80:80 my-web-app``   —Rodar esse comando apenas se quiser ver como ficou o programa



Faça login no Amazon Elastic Container Registry (Amazon ECR) através do CMD, com os comandos a seguir: Lembre de substituir YOUR_AWS_ACCOUNT_ID por seu ID Lembre também de pegar no output o URI, pois será utilizado. Será utilizado como URI + “:latest” :

``aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com``

``aws ecr create-repository --repository-name my-web-app``

O output deve ser algo assim: 
```PS C:\Users\cesar\OneDrive\Desktop\Insper\6 Semestre\Cloud\projeto_aws> aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 723424998361.dkr.ecr.us-east-1.amazonaws.com
Login Succeeded
PS C:\Users\cesar\OneDrive\Desktop\Insper\6 Semestre\Cloud\projeto_aws> aws ecr create-repository --repository-name my-web-app
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:723424998361:repository/my-web-app",
        "registryId": "723424998361",
        "repositoryName": "my-web-app",
        "repositoryUri": "723424998361.dkr.ecr.us-east-1.amazonaws.com/my-web-app",
        "createdAt": "2023-05-10T09:59:51-03:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
    
 ```
 
Rodar os comandos a seguir para subir a imagem para o repositório.

``docker tag my-web-app:latest 723424998361.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest``   —Substituir o número no início do endereço para o seu USER ID.

``docker push 723424998361.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest`` —Substituir o número no início do endereço para o seu USER ID.

Agora crie um diretório, na pasta do projeto, chamado terraform e em seguida navegue até ele e crie um arquivo chamado provider.tf, com o seguinte conteúdo:
```provider "aws" {
  region = "us-east-1"
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  version                = ">= 2.3.2"
}


data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}


Crie um arquivo chamado vpc.tf, com o seguinte conteúdo:
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"


  tags = {
    Name = "my-web-app-vpc"
  }
}


resource "aws_subnet" "this" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.this.id


  tags = {
    Name = "my-web-app-subnet"
  }
}

```

Crie uma keypair através do dashboard da AWS. Faça isso ao pesquisar na barra de pesquisa por key pairs. Em seguida abra a pagina key pairs e clique em criar par de chaves. Insira o nome que deseja e o tipo RSA. O formato de aquivo é o .pem e tags não são necessárias. Verifique se foi criada ao voltar para a página key pairs.

Crie um arquivo chamado eks.tf, como seguinte conteúdo:
```
locals {
  cluster_name = "my-web-app-cluster"
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"


  name = "my-vpc"
  cidr = "10.0.0.0/16"


  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]


  enable_nat_gateway = true
  enable_vpn_gateway  = true


}




module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.1.0" 


  cluster_name = local.cluster_name
  cluster_version = "1.23" 
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id


  node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 10
      min_capacity     = 1


      instance_type = "t3.medium"
      key_name      = "my-keypair" # substitua pelo nome da sua chave


      additional_tags = {
        Environment = "dev"
        Terraform = "true"
        Name        = "eks-worker-node"
}
}
}
}
```

Crie um arquivo kubernetes.tf, como seguinte conteúdo:
```
resource "kubernetes_deployment" "my_web_app_deployment"{
    metadata {
        name = "my-web-app"
    }


    spec {
        replicas = 3


        selector {
            match_labels = {
                App = "my-web-app"
            }
        }


        template {
            metadata {
                labels = {
                    App = "my-web-app"
                }
            }


            spec {
                container {
                    image = "723424998361.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest" # Substitua pela sua própria imagem / Troque o número inicial por seu ID de usuário
                    name  = "my-web-app"
                }
            }
        }
    }
}


resource "kubernetes_service" "my_web_app_service"{
    metadata {
        name = "my-web-app"
    }


    spec {
        selector = {
            App = "my-web-app"
        }


        port {
            port        = 80
            target_port = 80
        }


        type = "LoadBalancer"
    }
}

```
Crie também um arquivo chamado variable.tf com o seguinte conteúdo:
```
variable "region" {
  default     = "us-east-1"
}


variable "cluster_name" {
  default     = "my-web-app-cluster"
}

```

Com esses arquivos criados, execute no terminal os comandos:

``terraform init``

``terraform plan``

``terraform apply``

Em seguida execute esses comandos para verificar o endereço da aplicação:

``aws eks --region us-east-1 update-kubeconfig --name my-web-app-cluster``

``kubectl get services``

Na linha do output do segundo comando haverá um endereço, acesse ele e terá acesso à sua aplicação.
