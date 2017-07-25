#!/usr/bin/env groovy

/**
 * Jenkinsfile for cvprac rubygem
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
        emailTo = 'jere@arista.com'
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
            // wrap([$class: 'AnsiColorSimpleBuildWrapper', colorMapName: "xterm"]) {
                sh """
                    #!/bin/bash -l
                    set +x
                    source /usr/local/rvm/scripts/rvm
                    rvm use 2.3.3@cvprac-rb
                    set -x
                    bundle exec rake yard || true
                """
            // }
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
        success {
            mail body: "${env.JOB_NAME} (${env.BUILD_NUMBER}) ${env.projectName} build successful\n" +
                       "Started by ${env.BUILD_CAUSE}",
                 from: env.emailFrom,
                 //replyTo: env.emailFrom,
                 subject: "${env.projectName} ${env.JOB_NAME} (${env.BUILD_NUMBER}) build successful",
                 to: env.emailTo
        }
    }
}
