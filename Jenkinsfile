pipeline {
    agent none

    environment {
        SONARQUBE_TOKEN = credentials('sonar-token')
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_REPO = 'fercdevv/jenkins-node'
    }

    stages {
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

        stage('Listar carpetas y archivos del repo...') {
            agent {
                docker {
                    image 'node:20-alpine'
                }
            }
            steps {
                sh 'ls -la'
            }
        }

        stage('SonarQube Analisis...') {
            agent {
                docker {
                    image 'sonarsource/sonar-scanner-cli:latest'
                }
            }
            steps {
                withSonarQubeEnv() {
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

        stage('Construir y pushear imagen a dockerhub') {
            when {
                branch 'master'
            }

            agent {
                docker {
                    image 'docker:latest'
                }
            }

            steps {
                sh '''
                echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                docker build -t $DOCKER_REPO:latest .
                docker push $DOCKER_REPO:latest
                '''
            }
        }
}