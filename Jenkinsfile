#!/usr/bin/env groovy

REPOSITORY = 'content-store'

node {
   def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

   try {
      stage("Checkout") {
         checkout scm
      }

      stage("Build") {
        sshagent(['govuk-ci-ssh-key']) {
          sh "${WORKSPACE}/jenkins.sh"
        }
        step([
            $class: 'RcovPublisher',
            reportDir: "coverage/rcov",
            targets: [
                [metric: "CODE_COVERAGE", healthy: 75, unhealthy: 50, unstable: 30]
            ]
        ])
      }

      stage("Push release tag") {
         echo 'Pushing tag'
         govuk.pushTag(REPOSITORY, env.BRANCH_NAME, 'release_' + env.BUILD_NUMBER)
      }

      // Deploy on Integration (only master)
      govuk.deployIntegration(REPOSITORY, env.BRANCH_NAME, 'release', 'deploy')
   } catch (e) {
      currentBuild.result = "FAILED"
      step([$class: 'Mailer',
            notifyEveryUnstableBuild: true,
            recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
            sendToIndividuals: true])
      throw e
   }
}
