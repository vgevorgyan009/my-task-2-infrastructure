pipeline {
  agent any
  stages {
    stage("provisioning infrastructure") {
        environment {
            AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
            AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
        }
        steps {
            script {
                    sh "terraform init"
                    sh "terraform apply --auto-approve"
                    sh "cd separately_deploying_argocd_application"
                    sh "terraform init"
                    sh "terraform apply --auto-approve"
            }
        }
    }
   }
}