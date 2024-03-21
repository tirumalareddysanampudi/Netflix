pipeline{
    agent any
    tools{
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME=tool 'Sonar-Scanner'
    }
    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'main', credentialsId: 'Git-Hub', url: 'https://github.com/tirumalareddysanampudi/Netflix.git'
            }
        }
         stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Netflix \
                    -Dsonar.projectKey=Netflix '''
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-credential-token'
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'sudo apt-get install npm -y'
            }
        }
        stage('OWASP Dependency-Check Vulnerabilities') {
      steps {
        dependencyCheck additionalArguments: '''--scan   /root/.jenkins/workspace/Netflix/
--format	XML''', odcInstallation: 'Dp-Check'
        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
      }
    }
    stage('TRIVY FS SCAN') {
         steps {
             sh "trivy fs . > trivyfs.txt"
            }
        }
    stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'Docker', toolName: 'docker'){
                       sh "docker build --build-arg MY-NETFLIX=32793b941fdb8ee8ad904d9729feb174 -t netflix ."
                       sh "docker tag netflix tirumalareddydocker/netflix:latest "
                       sh "docker push tirumalareddydocker/netflix:latest "
                    }
                }
            }
        }
        stage("TRIVY"){
            steps{
                sh "trivy image tirumalareddydocker/netflix:latest > trivyimage.txt"
            }
        }
        
    }
    post {
     always {
        emailext attachLog: true,
            subject: "'${currentBuild.result}'",
            body: "Project: ${env.JOB_NAME}<br/>" +
                "Build Number: ${env.BUILD_NUMBER}<br/>" +
                "URL: ${env.BUILD_URL}<br/>",
            to: 'tirumalareddysanampudi@gmail.com',
            attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
        }
    }
}
