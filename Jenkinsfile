#!/usr/bin/env groovy

/**
 * Jenkinsfile for cvprac rubygem
 */

node() {

    currentBuild.result = "SUCCESS"

    try {

        stage ('Checkout') {

            checkout scm
            sh """
                source ~/.rvm/scripts/rvm
                rvm list
                #rvm use
                gem install bundler --no-ri --no-rdoc
                bin/setup
            """
        }

        stage ('Check_style') {

            try {
                sh """
                    bundle exec rake rubocop
                """
            }
            catch (Exception err) {
                currentBuild.result = "UNSTABLE"
            }
            echo "RESULT: ${currentBuild.result}"
        }

        stage ('RSpec Unittests') {

            sh """
                bundle exec rake cI_spec
            """

            step([$class: 'JUnitResultArchiver', testResults: 'result.xml'])

        }

        stage ('YARD doc generation') {

            // wrap([$class: 'AnsiColorSimpleBuildWrapper', colorMapName: "xterm"]) {
                sh """
                    bundle exec rake yard
                """
            // }
        }

        stage ('Cleanup') {

            echo 'Cleanup'

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

           mail body: "${env.BUILD_URL} build successful.\n" +
                      "Started by ${env.BUILD_CAUSE}",
                from: 'eosplus-dev+jenkins@arista',
                replyTo: 'eosplus-dev@arista',
                subject: "cvprac-rb ${env.JOB_NAME} (${env.BUILD_NUMBER}) build successful",
                to: 'jere@arista.com'

        }

    }

    catch (err) {

        currentBuild.result = "FAILURE"

            mail body: "${env.JOB_NAME} (${env.BUILD_NUMBER}) cookbook build error " +
                       "is here: ${env.BUILD_URL}\nStarted by ${env.BUILD_CAUSE}" ,
                 from: 'eosplus-dev+jenkins@arista.com',
                 replyTo: 'eosplus-dev+jenkins@arista.com',
                 subject: "cvprac-rb ${env.JOB_NAME} (${env.BUILD_NUMBER}) build failed",
                 to: 'jere@arista.com'

            throw err
    }

}
