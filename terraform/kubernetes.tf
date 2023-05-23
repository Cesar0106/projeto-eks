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
                    image = "723424998361.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest" # Replace with your own image
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
