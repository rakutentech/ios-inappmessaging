## Changelog

### 2.1.0 (2020-11-11)
- Added a campaign's context feature - a phrase enclosed in square brackets added to the campaign's title. Campaigns with contexts can be optionally validated by implementing a new method from the SDK. Validation occurs before displaying the message and decides about showing that message or not. [SDKCF-2871]
- Improvements:
	- Updated the locale parameter format in backend http requests [SDKCF-2401]
	- Improved unit tests code coverage [SDKCF-2245]
	- Improved campaign synchronization logic [SDKCF-2467]
	- Other minor improvements like: using xcconfig to set up secrets, Xcode 12 updates
- Bug fixes:
	- Fixed a bug where bottom body margin in Modal campaigns layout was missing [SDKCF-2496]
	- Full Screen campaign content is now not overlapping with system status bar [SDKCF-2444]
	- Fixed an issue when UI was blocked because of no internet connection [SDKCF-2842]
	- Fixed an issue when a user was able to see a message from previous user's cached data [SDKCF-2535]

### 2.0.0 (2020-06-30)
- Initial open sourced release
- This version is a major refactor. Highlights include:
    - Improved maintainability, testability and error handling
    - Removed 3rd party dependencies
    - Added CI automation with Fastlane/travis

#### Note: Previous SDK versions up to and including the most recently published version 1.4.0 were named `InAppMessaging`.
