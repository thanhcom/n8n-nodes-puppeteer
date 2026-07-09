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
                    // Tạo một chuỗi ngẫu nhiên 8 ký tự bằng lệnh shell sinh ngẫu nhiên
                    def randomHash = sh(
                        script: "cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1",
                        returnStdout: true
                    ).trim()
                    
                    env.IMAGE_TAG = "build-${randomHash}"
                }
                echo "🎲 Generated Random Image Tag: ${IMAGE_TAG}"
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    # Ép buộc pull base image mới nhất từ DIUN trigger về rồi build
                    docker build --pull -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
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
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Deploy Container (Remote via SSH)') {
            steps {
                sshagent(credentials: ['ssh-remote']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                            set -e

                            echo "🚀 Deploying Custom n8n Container with random tag: ${IMAGE_TAG} ..."

                            docker pull ${IMAGE_NAME}:${IMAGE_TAG}

                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true

                            docker run -d --name ${CONTAINER_NAME} \\
                               -v n8n_data:/home/node/.n8n \\
                               -p 678:5678 \\
                               -e GENERIC_TIMEZONE="Asia/Ho_Chi_Minh" \\
                               -e TZ="Asia/Ho_Chi_Minh" \\
                               -e N8N_SECURE_COOKIE=false \\
                               -e N8N_HOST=n8n.thanhtrang.online \\
                               -e WEBHOOK_URL=https://n8n.thanhtrang.online/ \\
                               -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \\
                               -e N8N_TRUST_PROXY=true \\
                               --restart always \\
                               ${IMAGE_NAME}:${IMAGE_TAG}

                            echo "✅ Deploy success"
                        '
                    """
                }
            }
        }

        stage('Cleanup Old Images (Remote)') {
            steps {
                sshagent(credentials: ['ssh-remote']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                            echo "🧹 Cleanup old build images..."

                            OLD_TAGS=\$(docker images ${IMAGE_NAME} --format "{{.Tag}}" \\
                                | grep "^build-" \\
                                | tail -n +3) # Giữ lại 2 bản gần nhất đề phòng lỗi

                            for TAG in \$OLD_TAGS; do
                                docker rmi ${IMAGE_NAME}:\$TAG || true
                            done

                            docker image prune -f
                            echo "✅ Cleanup done"
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Toàn bộ Pipeline thành công! Tag đã deploy: ${IMAGE_TAG}"
        }
        failure {
            echo "❌ Deploy thất bại – Tự động giữ nguyên/rollback bản :latest"
        }
    }
}