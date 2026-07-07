pipeline {
    agent any

    environment {
        // Cấu hình thông tin Image từ Repo của bạn
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

        stage('Prepare Image Tag') {
            steps {
                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                }
                echo "🔖 Puppeteer Image tag: ${IMAGE_TAG}"
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
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

                            echo "🚀 Deploying Custom n8n-Puppeteer Container ..."

                            docker pull ${IMAGE_NAME}:${IMAGE_TAG}

                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true

                            # Lệnh chạy container chuẩn cấu hình n8n của bạn
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

                            echo "✅ Deploy n8n with Puppeteer success"
                        '
                    """
                }
            }
        }

        stage('Cleanup Old Images (Remote)') {
            steps {
                // ĐÃ ĐỔI: Sử dụng ssh-remote credentials
                sshagent(credentials: ['ssh-remote']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                            echo "🧹 Cleanup old Puppeteer Docker images..."

                            OLD_TAGS=\$(docker images ${IMAGE_NAME} --format "{{.Tag}}" \\
                                | grep -v latest \\
                                | sort -r \\
                                | tail -n +2)

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
            echo "✅ Toàn bộ Pipeline thành công! n8n đang chạy tại: https://n8n.thanhtrang.online"
        }

        failure {
            echo "❌ Deploy thất bại – Tự động rollback về bản :latest ổn định trước đó"

            sshagent(credentials: ['ssh-remote']) {
                sh """
                    ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
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
                           ${IMAGE_NAME}:latest
                    '
                """
            }
        }
    }
}