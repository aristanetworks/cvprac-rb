#!/usr/bin/env groovy

/**
 * Declarative Jenkinsfile for cvprac rubygem
 *
 * See RVM setup instructions for nodes
 * https://rvm.io/integration/jenkins
 */
pipeline {
    agent { label 'puppet' }
    options {
        buildDiscarder(
            // Only keep the 10 most recent builds
            logRotator(numToKeepStr:'10'))
    }
    environment {
        projectName = 'cvprac rubygem'
        emailTo = 'eosplus-dev+jenkins@arista.com'
        emailFrom = 'eosplus-dev+jenkins@arista.com'
    }
    stages {
        stage ('Setup Env') {
            steps {
                sh """
                    #!/bin/bash -l
                    set +x
                    [[ -s /usr/local/rvm/scripts/rvm ]] && source /usr/local/rvm/scripts/rvm
                    /usr/local/rvm/bin/rvm list
                    rvm use 2.3.3@cvprac-rb --create
                    gem install bundler --no-ri --no-rdoc
                    set -x
                    which ruby
                    ruby --version
                    bin/setup
                """
            }
        }

        stage ('Check_style') {

            steps {
                sh """
                    #!/bin/bash -l
                    set +x
                    source /usr/local/rvm/scripts/rvm
                    rvm use 2.3.3@cvprac-rb
                    set -x
                    bundle exec rake rubocop || true
                """
            }
        }

        stage ('RSpec Unittests') {
            steps {
                sh """
                    #!/bin/bash -l
                    set +x
                    source /usr/local/rvm/scripts/rvm
                    rvm use 2.3.3@cvprac-rb
                    set -x
                    bundle exec rake ci_spec || true
                """

                step([$class: 'JUnitResultArchiver', testResults: 'results/*.xml'])
            }
        }

        stage ('YARD doc generation') {
            steps {
                sh """
                    #!/bin/bash -l
                    set +x
                    source /usr/local/rvm/scripts/rvm
                    rvm use 2.3.3@cvprac-rb
                    set -x
                    bundle exec rake yard || true
                """
            }
        }

        stage ('Deploy system testbed') {
            steps {
                /*
                when {
                    expression {
                        GIT_BRANCH = 'origin/' + sh(returnStdout: true, script: 'git rev-parse --abbrev-ref HEAD').trim()
               //         return !(GIT_BRANCH == 'origin/master' || params.FORCE_FULL_BUILD)
               //     }
               //     branch { 'master' }
               //     sh "ping -c 10 10.81.111.62"
               // }
                */
                script {
                    def setupResult = build job: 'Build_CVP_Testbed', parameters: [
                        string(name: 'FQDN_NAME', value: 'cvpracrb-cvp.rtp.aristanetworks.com'),
                        string(name: 'VSPHERE_FOLDER', value: 'cvprac-ruby'),
                        string(name: 'CVP_VERSION', value: '2017.1.0.1'),
                        string(name: 'CVP_ADDRESSES', value: "10.81.111.62"),
                        string(name: 'VEOS_VERSION', value: '4.16.6M-ztp'),
                        string(name: 'TOPOLOGY', value: 'flat'),
                        booleanParam(name: 'BUILD_TESTS', value: false),
                        booleanParam(name: 'TEARDOWN', value: false)
                    ]
                    def systest_build_number = setupResult.getNumber()
                    // Navigate to jenkins > Manage jenkins > In-process Script Approval
                    // staticMethod org.codehaus.groovy.runtime.DefaultGroovyMethods putAt java.lang.Object java.lang.String java.lang.Object
                    env['setup_build_number'] = setupResult.getNumber()
                }
            }
        }

        stage ('System tests') {
            steps {
                sh """
                    #!/bin/bash -l
                    set +x
                    source /usr/local/rvm/scripts/rvm
                    rvm use 2.3.3@cvprac-rb
                    set -x
                    bundle exec rake spec:system || true
                """

                step([$class: 'JUnitResultArchiver', testResults: 'results/*.xml'])
            }
        }

        stage ('Destroy system testbed') {
            steps {
                echo "ENV-setup_build_number: ${env.setup_build_number}"
                /*
                when {
                    expression {
                      PING_RES = sh(returnStdout: true, script: "ping -c 10 10.81.111.62").trim()
                      return PING_RES == 100
                    }
                }
                */
                build job: 'Destroy_CVP_Testbed', parameters: [
                    string(name: 'BUILD_SELECTOR', value: "<SpecificBuildSelector plugin='copyartifact@1.38.1'>  <buildNumber>${env.setup_build_number}</buildNumber></SpecificBuildSelector>")
                ]
                // echo sh(returnStdout: true, script: 'env')
            }
        }

        stage ('Archive artifacts') {
            when {
                anyOf { branch 'master'; branch 'develop' }
            }
            steps {
                sh """
                    #!/bin/bash -l
                    set +x
                    source /usr/local/rvm/scripts/rvm
                    rvm use 2.3.3@cvprac-rb
                    set -x
                    bundle exec rake build
                """
                archiveArtifacts artifacts: 'pkg/*.gemm', fingerprint: true, onlyIfSuccessful: true
            }
        }

        stage ('Cleanup') {

            steps {

            step([$class: 'WarningsPublisher',
                  canComputeNew: false,
                  canResolveRelativePaths: false,
                  consoleParsers: [
                                   [parserName: 'Rubocop'],
                                   [parserName: 'Rspec']
                                  ],
                  defaultEncoding: '',
                  excludePattern: '',
                  healthy: '',
                  includePattern: '',
                  unHealthy: ''
            ])

            step([
                $class: 'RcovPublisher',
                reportDir: "coverage/rcov",
                targets: [
                    [metric: "CODE_COVERAGE", healthy: 90, unhealthy: 80, unstable: 50]
                ]
            ])

            // publish html
            // snippet generator doesn't include "target:"
            // https://issues.jenkins-ci.org/browse/JENKINS-29711.
            publishHTML (target: [
                allowMissing: false,
                alwaysLinkToLastBuild: false,
                keepAll: true,
                reportDir: 'coverage',
                reportFiles: 'index.html',
                reportName: "RCov Report"
              ])
            publishHTML (target: [
                allowMissing: false,
                alwaysLinkToLastBuild: false,
                keepAll: true,
                reportDir: 'doc',
                reportFiles: 'index.html',
                reportName: "YARD Docs"
              ])
            }
        }
    }

    post {
        always {
            echo sh(returnStdout: true, script: 'env')
            mail body: "${env.JOB_NAME} (${env.BUILD_NUMBER}) ${env.projectName} build ${currentBuild.result}\n" +
                       "Started by ${env.BUILD_CAUSE}\n" +
                       "Run status: ${env.RUN_DISPLAY_URL}\n" +
                       "Project status: ${env.JOB_DISPLAY_URL}\n" +
                       "Changes in this build: ${env.RUN_CHANGES_DISPLAY_URL}\n" +
                       "Built on node: ${env.NODE_NAME}\n",
                 from: env.emailFrom,
                 //replyTo: env.emailFrom,
                 subject: "${env.projectName} ${env.JOB_NAME} (${env.BUILD_NUMBER}) build ${currentBuild.result}",
                 to: env.emailTo
        }
        success {
            echo sh(returnStdout: true, script: 'env')
            mail body: "${env.JOB_NAME} (${env.BUILD_NUMBER}) ${env.projectName} build success\n" +
                       "Started by ${env.BUILD_CAUSE}\n" +
                       "Run status: ${env.RUN_DISPLAY_URL}\n" +
                       "Project status: ${env.JOB_DISPLAY_URL}\n" +
                       "Changes in this build: ${env.RUN_CHANGES_DISPLAY_URL}\n" +
                       "Built on node: ${env.NODE_NAME}\n",
                 from: env.emailFrom,
                 //replyTo: env.emailFrom,
                 subject: "${env.projectName} ${env.JOB_NAME} (${env.BUILD_NUMBER}) build succeeded",
                 to: env.emailTo
        }
    }
}
