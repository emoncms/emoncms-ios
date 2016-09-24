#!/usr/bin/env bash

set -e

xcodebuild -workspace EmonCMSiOS.xcworkspace -scheme EmonCMSiOS -destination "platform=iOS Simulator,name=iPhone SE" clean test | xcpretty && exit ${PIPESTATUS[0]}
