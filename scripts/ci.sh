#!/usr/bin/env bash

set -e

xcodebuild -workspace EmonCMSiOS.xcworkspace -scheme EmonCMSiOS -destination "platform=iOS Simulator,name=iPhone XR" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO clean build test | xcpretty && exit ${PIPESTATUS[0]}
