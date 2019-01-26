#!/usr/bin/env bash

set -e

XCPRETTY="xcpretty -f `xcpretty-travis-formatter`"

scripts/intelligent-bootstrap
xcodebuild -project EmonCMSiOS.xcodeproj -scheme EmonCMSiOS -destination "platform=iOS Simulator,name=iPhone XR" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO clean build test | ${XCPRETTY} && exit ${PIPESTATUS[0]}
