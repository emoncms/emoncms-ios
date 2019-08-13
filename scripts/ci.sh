#!/usr/bin/env bash

set -e

XCPRETTY="xcpretty -f `xcpretty-travis-formatter`"

# Ensure we don't have hardware keyboard - it interferes with tests
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard 0

scripts/intelligent-bootstrap
xcodebuild \
	-project EmonCMSiOS.xcodeproj \
	-scheme EmonCMSiOS \
	-sdk ${TEST_SDK} \
	-destination "platform=iOS Simulator,OS=${OS},name=${NAME}" \
	CODE_SIGN_IDENTITY="" \
	CODE_SIGNING_REQUIRED=NO \
	clean build test \
	| ${XCPRETTY} && exit ${PIPESTATUS[0]}
