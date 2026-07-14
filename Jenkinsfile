pipeline {
    agent any

    environment {
        IMAGE_NAME     = "thanhcom/n8n-nodes-puppeteer"
        CONTAINER_NAME = "n8n"

        REMOTE_USER = "thanhcom"
        REMOTE_HOST = "100.72.72.26"
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

        stage('Deploy Container (Remote via SSH)') {
            steps {
                sshagent(credentials: ['ssh-remote']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "
                            set -e
                            echo '🚀 Deploying Custom n8n Container with tag: latest ...'

                            docker pull ${IMAGE_NAME}:latest

                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true

                            docker run -d --name ${CONTAINER_NAME} \\
                               -v n8n_data:/home/node/.n8n \\
                               -p 678:5678 \\
                               -e GENERIC_TIMEZONE='Asia/Ho_Chi_Minh' \\
                               -e TZ='Asia/Ho_Chi_Minh' \\
                               -e N8N_SECURE_COOKIE=false \\
                               -e N8N_HOST=n8n.thanhtrang.online \\
                               -e WEBHOOK_URL=https://n8n.thanhtrang.online/ \\
                               -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \\
                               -e N8N_TRUST_PROXY=true \\
                               --restart always \\
                               ${IMAGE_NAME}:latest

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
                            echo "🧹 Dọn dẹp các image cũ (dangling) do ghi đè tag latest..."
                            
                            # Khi pull latest mới về, image cũ sẽ bị mất tag và chuyển thành <none>
                            # Lệnh prune này sẽ xóa sạch các image dạng <none> đó cực kỳ an toàn
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