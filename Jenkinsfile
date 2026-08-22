pipeline {
    agent any

    environment {
        IMAGE_NAME     = "thanhcom/n8n-nodes-puppeteer"
        CONTAINER_NAME = "n8n"

        REMOTE_USER = "thanhcom"
        REMOTE_HOST = "100.72.72.26"
        
        // Thư mục chứa docker-compose.yml và .env chuẩn trên server của bạn
        REMOTE_DIR  = "/home/thanhcom/n8n" 
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/thanhcom/n8n-nodes-puppeteer.git',
                    branch: 'main'
            }
        }

        stage('Docker Build & Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        docker build --pull -t ${IMAGE_NAME}:latest .

                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
            post {
                always {
                    sh '''
                        echo "🧹 Đang xóa image vừa build trên máy Jenkins để tiết kiệm dung lượng..."
                        docker rmi ${IMAGE_NAME}:latest || true
                        docker image prune -f
                    '''
                }
            }
        }

        stage('Deploy Container (Remote via Docker Compose)') {
            steps {
                sshagent(credentials: ['ssh-remote']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "
                            set -e
                            echo '🚀 Updating and deploying n8n stack via Docker Compose...'

                            cd ${REMOTE_DIR}

                            # Pull image mới nhất từ DockerHub
                            docker compose pull n8n

                            # Khởi động lại service n8n bằng docker compose up -d
                            docker compose up -d --no-deps n8n

                            echo '✅ Deploy thành công lên server!'
                        "
                    '''
                }
            }
        }

        stage('Cleanup Old Images (Remote)') {
            steps {
                sshagent(credentials: ['ssh-remote']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                            echo "🧹 Dọn dẹp các image cũ (dangling) trên server..."
                            docker image prune -f
                            echo "✅ Đã dọn dẹp xong"
                        '
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Toàn bộ Pipeline chạy ngon lành cành đào!"
        }
        failure {
            echo "❌ Pipeline toang, kiểm tra lại log xem lỗi bước nào!"
        }
    }
}
