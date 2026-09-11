pipeline {
    agent any

    environment {
        IMAGE_NAME = 'devsecops-flask-app'
        BUILD_TAG  = "${BUILD_NUMBER}"
    }

    stages {
        stage('1. Checkout Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/JimilPrabtani/DevSecOps-Project-3.git'
            }
        }

        stage('2. Secret & Code Security (SAST)') {
            steps {
                echo 'Running Bandit Static Application Security Testing...'
                sh 'pip install bandit pip-audit || true'
                sh 'bandit -r . -x ./venv -ll || true'
            }
        }

        stage('3. Dependency Vulnerability Audit') {
            steps {
                echo 'Auditing Python dependencies...'
                sh 'pip-audit -r requirement.txt || true'
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
                sh 'sleep 10'
                sh 'curl -f http://localhost/healthz || exit 1'
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