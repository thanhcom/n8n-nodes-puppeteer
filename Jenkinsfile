pipeline {
    agent any

    environment {
        IMAGE_NAME = "thanhcom/n8n-nodes-puppeteer"
        // Gọi URL Webhook từ Credentials của Jenkins để đảm bảo bảo mật
        PORTAINER_WEBHOOK = credentials('PORTAINER_N8N_WEBHOOK') 
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/thanhcom/n8n-nodes-puppeteer.git',
                    branch: 'main'
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    # Ép buộc pull base image mới nhất rồi build bản :latest
                    docker build --pull -t ${IMAGE_NAME}:latest .
                '''
            }
        }

        stage('Docker Login & Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Trigger Portainer Deploy') {
            steps {
                echo "🚀 Đang kích hoạt Portainer Webhook để tự động Deploy..."
                sh """
                    curl -X POST "${PORTAINER_WEBHOOK}"
                """
                echo "✅ Đã gửi tín hiệu cập nhật ứng dụng tới Portainer thành công!"
            }
        }
    }

    post {
        success {
            echo "✅ Toàn bộ Pipeline thành công! Portainer đang tiến hành Recreate Container."
        }
        failure {
            echo "❌ Pipeline thất bại tại một trong các bước Build/Push/Webhook."
        }
    }
}