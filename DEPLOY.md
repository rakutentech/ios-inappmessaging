# RInAppMessaging iOS SDK

1. [Preparation](#preparation)
1. [Deploy](#deploy)

## Preparation
Create pull request to make the following changes:

1. Update the date in `CHANGELOG.md`
1. Update version number in `openapi.yaml`
1. Update version number in `.jazzy.yaml`
1. Update version number in `RInAppMessaging.podspec`
1. Update version number in `Sources/RInAppMessaging/RInAppMessaging/Constants.swift` under `sdkVersion` constant
1. Add version number to `_versions` file

## Deploy

Push a tag (example: 7.2.0)

### Using CI

Run `deploy` lane on Bitrise. (Should be automatically triggered after pushing a tag)

### Using local script
(in case Bitrise workflow failed or wasn't triggered)

Run following commands:
```bash
bundle install
bundle exec pod spec lint --allow-warnings
bundle exec pod trunk push --allow-warnings --verbose
bundle exec fastlane deploy_ghpages ghpages_url:"https://github.com/rakutentech/ios-inappmessaging" github_token:<GitHub personal access token>
```
