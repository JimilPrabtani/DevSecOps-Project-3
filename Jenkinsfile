pipeline {
    agent any

    environment {
        IMAGE_NAME = 'trident-devsecops-app'
        BUILD_TAG  = "${BUILD_NUMBER}"
    }

    stages {
        stage('1. Checkout Repository') {
            steps {
                echo 'Checking out the repository...'
                git branch: 'main', url: 'https://github.com/JimilPrabtani/DevSecOps-Project-3.git'
            }
        }

        stage('2. Secret & Code Security (SAST)') {
            steps {
                echo 'Running Bandit Static Application Security Testing...'
                sh 'pip install bandit pip-audit || true'
                sh 'bandit -r . -x ./venv,./.venv,./terraform,./.git -ll || true'
            }
        }

        stage('3. Dependency Vulnerability Audit') {
            steps {
                echo 'Auditing Python dependencies...'
                sh 'pip-audit -r requirements.txt || true'
            }
        }

        stage('4. Build 3-Tier Container Images') {
            steps {
                echo 'Building production container image...'
                sh "docker build -t ${IMAGE_NAME}:${BUILD_TAG} ."
            }
        }

        stage('5. Container Vulnerability Scan (Trivy)') {
            steps {
                echo 'Running Trivy container vulnerability scan...'
                sh "trivy image --severity HIGH,CRITICAL ${IMAGE_NAME}:${BUILD_TAG} || true"
            }
        }

        stage('6. Deploy 3-Tier Architecture') {
            steps {
                echo 'Deploying 3-Tier Application with Docker Compose...'
                sh 'docker compose down || true'
                sh 'docker compose up -d --build'
            }
        }

        stage('7. Post-Deployment Health Check') {
            steps {
                echo 'Verifying Tier 1 & Tier 2 health status...'
                sh '''
                    for i in 1 2 3 4 5 6; do
                      if curl -f http://localhost/healthz; then exit 0; fi
                      echo "Health check attempt $i/6 failed, retrying in 10s..."
                      sleep 10
                    done
                    echo 'Health check failed after 6 attempts'
                    exit 1
                '''
            }
        }
    }

    post {
        always {
            echo 'DevSecOps Pipeline Execution Finished.'
        }
        success {
            echo 'Pipeline Succeeded: 3-Tier DevSecOps Application deployed successfully!'
        }
        failure {
            echo 'Pipeline Failed: Please review security logs above.'
        }
    }
}