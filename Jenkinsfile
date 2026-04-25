pipeline {
    agent none

    environment {
        SONARQUBE_TOKEN = credentials('sonar-token')
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_REPO = 'fercdevv/jenkins-node'
        TRIVY_CACHE_DIR = '/tmp/trivy-cache'
        AWS_REGION = 'us-east-1'
        STACK_NAME = 'stack-ecs-fargate'


    }

    stages {
        stage("Check cambios") {
            agent any 
            steps {
                script {
                    def changes = sh(
                        script: "git diff --name-only HEAD~1 HEAD",
                        returnStdout: true
                    ).trim()

                    if (!changes) {
                        echo "No hay cambios en repo"
                        env.SKIP_BUILD_AND_PUSH = "true"
                    } else {
                        echo "Archivos modificados:\n${changes}"
                    }
                }
            }
        }

        stage('Instalar dependencias...') {
            agent {
                docker {
                    image 'node:20-alpine'
                }
            }
            steps {
                echo 'Listando todas las carpetas y archivos...'
                sh 'npm install'
            }
        }

        stage('Ejecutar tests...') {
            agent {
                docker {
                    image 'node:20-alpine'
                }
            }
            steps {
                echo 'Listando todas las carpetas y archivos...'
                sh 'npm run test'
            }
        }

        stage('SonarQube Analisis...') {
            agent {
                docker {
                    image 'sonarsource/sonar-scanner-cli:latest'
                }
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                        sh "sonar-scanner"
                }
            }
        }

        stage('SonarQube quality gate...') {
            agent any
            steps {
                waitForQualityGate abortPipeline: true
            }
        }

        stage('Build docker image') {
            when {
                allOf {
                    branch 'master'
                    expression { env.SKIP_BUILD_AND_PUSH != "true" }
                }
            }
            
            agent {
                docker {
                    image 'docker:latest'
                }
            }
            steps {
                sh '''
                docker build -t $DOCKER_REPO:latest .
                '''
            }
        }

        stage('Trivy Scan') {
            when {
                branch 'qa'
            }
            agent {
                docker {
                    image 'aquasec/trivy:latest'
                    args '--entrypoint=""'
                }
            }
            steps {
                sh '''
                trivy image \
                --cache-dir $TRIVY_CACHE_DIR \
                --scanners vuln \
                --severity HIGH,CRITICAL \
                --exit-code 1 \
                --timeout 5m \
                $DOCKER_REPO:latest
                '''
            }
        }

        stage('Pushear imagen a dockerhub') {
            when {
                allOf {
                    branch 'master'
                    expression { env.SKIP_BUILD_AND_PUSH != "true" }
                }
            }
            agent {
                docker {
                    image 'docker:latest'
                }
            }

            steps {
                sh '''
                echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                docker push $DOCKER_REPO:latest
                '''
            }
        }

        stage("Deploy ECS FARGATE") {
            when {
                allOf {
                    branch 'master'
                    expression { env.SKIP_BUILD_AND_PUSH != "true" }
                }
            }

            agent {
                docker { 
                    image 'amazon/aws-cli:latest'
                    args '--entrypoint ""'    
                }
            }

            steps {
                withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                    sh '''
                    aws cloudformation deploy \
                      --template-file infra/ecs.yml \
                      --stack-name $STACK_NAME \
                      --capabilities CAPABILITY_NAMED_IAM \
                      --parameter-overrides \
                        ImageUrl=$DOCKER_REPO:latest \
                        VpcId=vpc-0a3cd97730bc5332b \
                        Subnets="subnet-084371090cddeab02,subnet-08ee9a8fbd634ee19,subnet-0233ac4ffbd7f09c9,subnet-081e593c9cc8b1376,subnet-0790db53816907cc4,subnet-0a8702af878a5a838"
                    '''
                }
            }
        }
    }
}