node {
    checkout scm

    // TODO: Move the part below into a separate groovy file

    // ------ SETUP ------ //

    user_initials = 'myapp'
    oracle_client_release = '11.2.0.4.4'
    oracle_server_release = '12.2.0.1'
    database_name = 'app'

    // ------  END  ------ //

    slaveId = sh(returnStdout: true, script: "hostname").trim()
    database = "db_$slaveId"
    network = "net_$slaveId"
    app_be = "be_$slaveId"
    port_docker = '1521'

    def dbServerImage = docker.image("dockerhub.rnd.ourcompany.com:5002/ops-smn/oracledb:${oracle_server_release}")
    dbServerImage.pull()

    try {
            sh "docker network create $network"

            stage('Run docker with DB') {
                dbServerImage.withRun("-h '$database' --name '$database' --network '$network'") {
                sh "echo 'ORACLESIDls            = (DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = $database) (PORT = $port_docker))) (CONNECT_DATA = (SID = ORACLESID) (SERVER = DEDICATED)))' > ${WORKSPACE}/tnsnames.ora"
                docker.image('dockerhub.rnd.ourcompany.com:6000/swf/0.0.18').inside("-u root -v /remote:/remote:ro -h dockcont1 --name '$app_be' --network '$network'") {
                        stage('Environment setup') {
                            // Setting variables basing on docker env values
                            home_path = sh(returnStdout: true, script: 'echo -n ${HOME}')
                            bin_path = sh(returnStdout: true, script: 'echo -n ${PATH}')
                            ld_path = sh(returnStdout: true, script: 'echo -n ${LD_LIBRARY_PATH}')
                        }

                    withCredentials([usernamePassword(credentialsId: 'SWB_USER', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                        withEnv(["APPLICATION_ROOT=${WORKSPACE}/install",
                                 "PHASE=LOCAL",
                                 "DOCKER_RUN=1",
                                 "DB_USER=${user_initials}",
                                 "DB_SCHEMA=owner${user_initials}",
                                 "DB_SERVICE=ORACLESIDls",
                                 "ORACLE_HOME=/tools/oracle/products/${oracle_client_release}",
                                 "ORACLE_BASE=/tools/oracle/products",
                                 "TNS_ADMIN=${WORKSPACE}",
                                 "TOOLS_PATH=/project/tools",
                                 "PATH=/tools/oracle/products/${oracle_client_release}/bin:${bin_path}",
                                 "COMPONENT_NAME=MY_NAME"])
                                 // be carreful, withEnv bases on master node env not the one set during docker run
                    parallel (
                        build_code:
                        {
                            stage('Check dependencies') {
                                sh '/project/scripts/test_deps.py'
                            }
                            stage('Build in development mode') {
                                sh '/project/scripts/build_source.py --mode dev --gcov --with_unittests'
                            }
                            stage('Coverage') {
                                sh '/project/scripts/build_source.py gcov --gcov --xml --mode=component'
                            }
                            stage('Sonar configure') {
                                sh '/project/scripts/sonar_configure.py'
                            }
                        },
                        build_database: {
                                // Wait for DB readiness
                                sleep(time: 2, unit: 'MINUTES')
                                // TO DO: replace sleep 2m with marker file

                                stage('Build DB') {
                                    sh "/project/scripts/build_database.py --db ${database_name}"
                            }
                        }
                    )
                    notifier('Unittests') {
                        stage('Unittests') {
                            retry(2) {
                                sh '/project/scripts/runtest.py --mode valgrind'
                            }
                        }
                        return "Done"
                    }
                    stage('Build in release mode')
                    {
                        sh '/project/scripts/build_source.py --mode release'
                    }
                    parallel (
                    component_test: {
                        stage('Install application') {
                            withEnv(["RECEPTOR_PORT=8900",
                                     "FRM_PORT_NB=10000"] ) {
                                sh  '''
                                        git clone https://$USERNAME:$PASSWORD@rnd.ourcompany.com/git/scm/APP/config.git
                                        mkdir ${APPLICATION_ROOT}
                                        cd ${APPLICATION_ROOT}
                                        /project/scripts/install_application.py -cn ${COMPONENT_NAME}
                                    '''
                            }
                        }
                        stage('Start application with backend services') {
                            sh  '''
                                    cd ${APPLICATION_ROOT}
                                    /project/scripts/start_application.py -cn ${COMPONENT_NAME}
                                '''
                        }
                        notifier('Non-regression testing') {
                            stage('Non-regression tests')
                            {
                                withEnv(["DB_HOST=$database",
                                         "DB_PORT=$port_docker"]) {
                                    sh '/project/scripts/non_regression.py --config regression/non_regression.rc''
                                }
                            }
                        }
                        notifier('Deliver') {
                            stage('Deliver') {
                                    sh  '''
                                            /project/scripts/deliver_component.py -cn ${COMPONENT_NAME} --phase DEV
                                        '''
                                    archiveArtifacts artifacts: './tarball/${COMPONENT_NAME}/*.tar.gz', allowEmptyArchive: true 
                            }
                           return 'Done'
                        }
                },
                sonar: {
                    notifier('Sonar analysis') {
                        stage('Sonar analysis') {
                            withSonarEnv('Sonar') {
                               withCredentials([[$class: 'UsernamePasswordMultiBinding', 
                                                 credentialsId: USERID, 
                                                 usernameVariable: 'SONAR_USER', 
                                                 passwordVariable: 'SONAR_PASSWORD']]) {
                                    def branchKey = "${COMPONENT_NAME}.$env.BRANCH_NAME"
                                    def projectKey = "APP_KEY"
                                    def projectName = "NEW_PROJECT"
                                    sh "curl -u $SONAR_USER:$SONAR_PASSWORD -X POST '$SONAR_HOST_URL/api/projects/create?key=$projectKey&name=$projectName"
                                    def sonarLogs = sh(returnStdout: true, script: "/sonar-runner/bin/sonar-runner -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_USER -Dsonar.password=$SONAR_PASSWORD -Dsonar.projectKey=$projectKey:$branchKey")
                                    echo sonarLogs
                                    return extractSonarResults(sonarLogs)

                               } //withCredentials
                            } // withSonarEnv
                        } // Sonar analysis
                    }
                } // sonar
            ) // parallel
            } // withEnv
            } // withCredentials
            }
        } // dbServerImage.withRun
    }
    }
    finally {
        stage('Clean-up') {
            sh "docker network rm $network"
            // Workspace cleanup
            step([$class: 'WsCleanup'])
        }
    }
} // node
