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

        stage('Prepare Random Tag') {
            steps {
                script {
                    // Sinh chuỗi ngẫu nhiên 8 ký tự làm tag để tránh trùng lặp
                    def randomHash = sh(
                        script: "cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1",
                        returnStdout: true
                    ).trim()
                    
                    env.IMAGE_TAG = "${randomHash}"
                }
                echo "🎲 Generated Random Image Tag: ${IMAGE_TAG}"
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
                    // Dùng nháy đơn để an toàn, bảo mật biến pass của DockerHub
                    sh '''
                        docker build --pull -t ${IMAGE_NAME}:${IMAGE_TAG} .
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest

                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Deploy Container (Remote via SSH)') {
            steps {
                sshagent(credentials: ['ssh-remote']) {
                    // Dùng nháy đơn bao ngoài, bọc biến môi trường bằng '${IMAGE_TAG}' để pass từ Jenkins sang SSH ngon lành
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "
                            set -e
                            echo '🚀 Deploying Custom n8n Container with tag: '${IMAGE_TAG}' ...'

                            # Ép server kéo đúng bản tag vừa build về, không lo trơ hay cache
                            docker pull ${IMAGE_NAME}:${IMAGE_TAG}

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
                               ${IMAGE_NAME}:${IMAGE_TAG}

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
                            echo "🧹 Dọn dẹp các bản build cũ..."

                            OLD_TAGS=$(docker images '${IMAGE_NAME}' --format "{{.Tag}}" | grep "^build-" | tail -n +2)

                            for TAG in $OLD_TAGS; do
                                docker rmi '${IMAGE_NAME}':$TAG || true
                            done

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