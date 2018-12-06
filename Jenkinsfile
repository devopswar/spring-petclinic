pipeline {
    agent { 
        label 'ubuntu' 
    }
   
    stages {
        stage ('Initialize and setup LogStash') {
            steps {
                sh '''
                    echo "PATH = ${PATH}"
                    echo "M2_HOME = ${M2_HOME}"
                '''
                    
                logstashSend failBuild: true, maxLines: 1000


                // **** GRAB db password and username from Conjur ****
                   
                script {
                        def conjur_url = 'https://ec2-54-193-30-240.us-west-1.compute.amazonaws.com'
                        def conjur_org = 'devopswar';
                        def conjur_apitoken = '3jp44983vmy3se1mmzsgk2g9qh3x29v9jnv1mmwev521x84p23gka0x8';
                        def _token = sh(returnStdout: true, script: "curl -k -XPOST ${conjur_url}/authn/${conjur_org}/host%2ffrontend%2ffrontend-01/authenticate -d ${conjur_apitoken}  | base64 | tr -d '\r\n'").trim()
                        println _token;
                        def _pwd   = sh(returnStdout: true, script: "curl -k ${conjur_url}/secrets/${conjur_org}/variable/db/password -H 'Authorization: Token token=\"${_token}\"'").trim()
                        def _user  = sh(returnStdout: true, script: "curl -k ${conjur_url}/secrets/${conjur_org}/variable/db/username -H 'Authorization: Token token=\"${_token}\"'").trim()
                        //println _pwd;
                        //println _user;
                }
                
                checkout scm
            }
        }

        stage ('Build Dev & Test Sonar') {
            steps {
                    // ----- this has been moved to Ansible -----
                    //sh 'sudo apt-get install -y default-jdk'
                    //sh 'sudo apt-get install -y mysql-client-5.7'
                    script {
                            ansibleTower credential: '', extraVars: '', importTowerLogs: false, 
                                         importWorkflowChildLogs: false, inventory: '', jobTags: '', 
                                         jobTemplate: 'config-worker_git_conjur', jobType: 'run', limit: '', removeColor: false, 
                                         skipJobTags: '', templateType: 'job', towerServer: 'ansible1', verbose: true                    

                            sh 'sudo ~/mvnw clean'

                            docker.image('sonarqube').withRun('-p 9092:9092 -p 9000:9000') { c ->
                                 // wait for the sonar container to be up and running
                                 sh 'sleep 20'
/*                                     
                                 withCredentials([usernamePassword(credentialsId: 'devmysql', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {   
                                     withSonarQubeEnv('sonarqube') {
                                         sh 'sudo ~/mvnw package -P dev  -Dmaven.test.skip=true sonar:sonar' 
                                     } // end withSonar
                                 } // end withCreds
*/                                 
                            }
                    } // script
            }
            post {
                success {
                    echo 'build dev & sonar success' 
                }
            }
        } // end stage build
            
        stage ('Functional Tests') {
                 steps {
                     script {
                        withCredentials([usernamePassword(credentialsId: 'devmysql', usernameVariable: 'MYSQL_DB_USER', passwordVariable: 'MYSQL_DB_PASSWORD')]) 
                        {   
                            docker.image('mysql:5.7.8').withRun('-e MYSQL_ROOT_PASSWORD=$MYSQL_DB_PASSWORD -e MYSQL_DATABASE=petclinic -p 3306:3306') { c ->
                                    /* Wait until mysql service is up */
                                    sh 'while ! mysqladmin ping -h0.0.0.0 --silent; do sleep 1; done'

                                    // setup the database
                                    sh 'mysql --protocol tcp -h localhost -u $MYSQL_DB_USER --password="$MYSQL_DB_PASSWORD" petclinic < ./src/main/resources/db/mysql/schema.sql'
                                    sh 'mysql --protocol tcp -h localhost -u $MYSQL_DB_USER --password="$MYSQL_DB_PASSWORD" petclinic < ./src/main/resources/db/mysql/data.sql'

                                    /* Run some tests which require MySQL */
                                    // after the mysql is up -> run the target
                                    sh 'sudo -E ~/mvnw test -P test' 
                                 } // end docker run
                         } // end withCreds
                     } // end script
                } // end steps
        } // end stage test

        // wait for user input before Deploying
        stage ('wait for input') { 
               steps { 
                   input id: 'Deploy', message: 'Proceed with Green node deployment?', ok: 'Deploy!'                       
               }    
        }
            
        stage ('Build Release') {
            steps {
                    //sh 'sudo apt-get install -y default-jdk'
                    //sh 'sudo apt-get install -y mysql-client-5.7'

                    withCredentials([usernamePassword(credentialsId: 'mysql-release', usernameVariable: 'MYSQL_RELEASE_DB_USER', passwordVariable: 'MYSQL_RELEASE_DB_PASSWORD')]) {   
                         sh 'sudo -E ~/mvnw package -Dmaven.test.skip=true -P release' 
                    } // end withCreds
            }
            post {
                success {
                    echo 'build release success' // run sonarqube tests here...   junit 'target/surefire-reports/**/*.xml' 
                }
            }
        } // end stage build
            
        stage ('Deploy') {
              environment { 
                MYSQL_RELEASE_DB_PASSWORD = 'value2'
                MYSQL_RELEASE_DB_USER     = 'value1'
               }            
               steps {
                       script {
                            app = docker.build( "devopswar/petclinic")
                            docker.withRegistry('https://registry.hub.docker.com', 'dockerhub-devopswar') {
                                    app.push("${env.BUILD_NUMBER}")
                                    app.push("latest")
                            }        

                                    
                            withKubeConfig(caCertificate: '', contextName: '', credentialsId: 'kubeconfig-file', serverUrl: '') 
                            {
//                                 withCredentials([usernamePassword(credentialsId: 'mysql-release', usernameVariable: 'MYSQL_RELEASE_DB_USER', passwordVariable: 'MYSQL_RELEASE_DB_PASSWORD')]) 
                                 //{
                                 //withCredentials([conjurSecretCredential(credentialsId: 'CONJUR_MYSQL_PASSWORD', variable: 'MYSQL_RELEASE_DB_PASSWORD'), conjurSecretCredential(credentialsId: 'CONJUR_MYSQL_USERNAME', variable: 'MYSQL_RELEASE_DB_USER')])
//                                 {
                                         
                                def conjur_url = 'https://ec2-54-193-30-240.us-west-1.compute.amazonaws.com'
                                def conjur_org = 'devopswar';
                                def conjur_apitoken = '3jp44983vmy3se1mmzsgk2g9qh3x29v9jnv1mmwev521x84p23gka0x8';
                                def _token = sh(returnStdout: true, script: "curl -k -XPOST ${conjur_url}/authn/${conjur_org}/host%2ffrontend%2ffrontend-01/authenticate -d ${conjur_apitoken}  | base64 | tr -d '\r\n'").trim()
                                println _token;
                                environment {
                                    MYSQL_RELEASE_DB_PASSWORD = sh(returnStdout: true, script: "curl -k ${conjur_url}/secrets/${conjur_org}/variable/db/password -H 'Authorization: Token token=\"${_token}\"'").trim()
                                    MYSQL_RELEASE_DB_USER = sh(returnStdout: true, script: "curl -k ${conjur_url}/secrets/${conjur_org}/variable/db/username -H 'Authorization: Token token=\"${_token}\"'").trim()
                                }
                                         
                                     //echo "password=$MYSQL_RELEASE_DB_PASSWORD"
                                     //echo "username=$MYSQL_RELEASE_DB_USER"
                                         /*
                                     withCredentials([[$class: 'ConjurSecretCredentialsBinding', credentialsId: 'CONJUR_MYSQL_USERNAME', secretVariable: 'MYSQL_RELEASE_DB_USER', descriptionVariable: 'mysql password']]) 
                                     {
                                     */
                                      // delete previous run
                                      // sh 'kubectl delete deploy petclinic || true'                                    
                                      //sh 'kubectl run petclinic --replicas=5 --labels="run=petclinic" --image=devopswar/petclinic --image-pull-policy Always'

                                        sh '''
```kubectl apply -f - <<EOF
apiVersion: apps/v1beta1 #for versions before 1.6.0 use extensions/v1beta1
kind: Deployment
metadata:
  name: petclinic
  namespace: default
  labels:
    app: petclinic
spec:
  replicas: 5
  template:
    metadata:
      labels:
        app: petclinic
    spec:
      containers:
      - name: petclinic
        image: devopswar/petclinic
        imagePullPolicy: Always
        env:
        - name: MYSQL_RELEASE_DB_USER
          valueFrom:
            secretKeyRef:
              name: db-user-pass
              key: username
        - name: MYSQL_RELEASE_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-user-pass
              key: password
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: petclinic
  namespace: default
  labels:
    app: petclinic
spec:
  type: LoadBalancer
  selector:
    app: petclinic
  ports:
  - name: http
    port: 80
    targetPort: 8080
    nodePort: 32052
    protocol: TCP
EOF```


/*
kubectl apply -f - <<EOF
apiVersion: apps/v1beta1 #for versions before 1.6.0 use extensions/v1beta1
kind: Deployment
metadata:
  name: petclinic
  labels:
    app: petclinic
spec:
  replicas: 5
  template:
    metadata:
      labels:
        app: petclinic
    spec:
      containers:
      - name: petclinic
        image: devopswar/petclinic
        imagePullPolicy: Always
        env:
        - name: BUILD_NUMBER
          value: "$BUILD_NUMBER"
        - name: MYSQL_RELEASE_DB_USER
          value: $MYSQL_RELEASE_DB_USER
        - name: MYSQL_RELEASE_DB_PASSWORD
          value: $MYSQL_RELEASE_DB_PASSWORD
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: petclinic
  labels:
    app: petclinic
spec:
  type: LoadBalancer
  selector:
    app: petclinic
  ports:
  - name: http
    port: 80
    targetPort: 8080
    nodePort: 32052
    protocol: TCP
EOF
'''                 
*/                                
                            } // end kubeconfig
                       } // endscript
               }
        }
    } // end stages
} // end pipeline


