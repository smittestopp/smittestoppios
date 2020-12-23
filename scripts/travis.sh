#!/bin/sh
# Fail build if linting fails
set -e
./Pods/SwiftFormat/CommandLineTool/swiftformat --lint .
set +e

if [[ "$BRANCH" == "develop" ]]; then

	# set GIT_COMMIT for display in the app
	GIT_RELEASE_VERSION=$(git describe --tags --always --dirty | sed -e 's/-rc[0-9]*//')
	/usr/libexec/PlistBuddy -c "Set :GIT_COMMIT ${GIT_RELEASE_VERSION}" "Corona/Info.plist"

	# # for git push of build number increment
	git remote set-url origin https://${GITHUB_TOKEN}@github.com/... > /dev/null 2>&1
	git config --global user.name "username"
	git config --global user.email "useremail"

	export FASTLANE_ITC_TEAM_ID=11111111111
	# run fastlane
	bundle exec fastlane dev_build
	exit $?
else
	bundle exec fastlane testall
    exit $?
fi