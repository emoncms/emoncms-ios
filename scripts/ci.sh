#!/usr/bin/env bash

set -e

xcodebuild -workspace EmonCMSiOS.xcworkspace -scheme EmonCMSiOS -sdk iphonesimulator -destination "name=iPhone SE" test | xcpretty
