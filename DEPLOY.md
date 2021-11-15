## Preparation
Create pull request to make the following changes:

1. Update `CHANGELOG.md`
1. Update version number in `openapi.yaml`
1. Update version number in `.jazzy.yaml`
1. Update version number in `RInAppMessaging.podspec`
1. Update version number in `Sources/RInAppMessaging/Resources/Versions.plist` under `IAMCurrentModuleVersion` key
1. Add version number to `_versions` file

## Deploy

### Using CI

Run `deploy` lane on Bitrise

### Manually

Run following commands:
```bash
bundle install
bundle exec pod spec lint --allow-warnings
bundle exec pod trunk push --allow-warnings --verbose
bundle exec fastlane deploy_ghpages ghpages_url:"https://github.com/rakutentech/ios-inappmessaging" github_token:<GitHub personal access token>
```

