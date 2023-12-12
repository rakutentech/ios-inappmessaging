## Changelog

### Unreleased

### 8.1.0 (2023-12-12)
- Features:
	- Added User preference input in Sample App [SDKCF-6641]
	- Added device_id to all the RAT events [SDKCF-6625]
	- Added device_id to DisplayPermission request header [SDKCF-6624]
	- Prevent calling `configure()` then RMC module is integrated [SDKCF-6710]
	- Added rmcsdk version parameter to all api calls [SDKCF-6709]
- Improvements:
	- Retaining API calls until configure() is called [SDKCF-6812]
- Fixes:
	- Fixed Xcode 15 beta errors [SDKCF-6692]
	- Fixed Finding RMC Bundle [SDKCF-6751]
	- Fixed Loading cached user data before IAM initialisation [SDKCF-6826]
        
### 8.0.0 (2023-06-21)
- **Breaking changes:**
    - Update Swift version support for package to 5.7.1 [SDKCF-6515]
- Features:
	- Added SwiftUI support for Sample App [SDKCF-5026]
	- Added SwiftUI support for Tooltip feature [SDKCF-5025]
- Bug fixes:
	- Removed "last user" cache to avoid overwriting anonymous user cache during init [SDKCF-6409]
	- Added display permission service to perform ping on tooltip dispatcher [SDKCF-4964]
	- Fix broken UIKit framework UI on dark mode [SDKCF-6587]
- Improvements:
	- Created new test scheme to combine unit test and UI test results [SDKCF-6356]
	- Refactored Event classes and removed unused code [SDKCF-6376]
	- Update api documentation [SDKCF-6592]
	- Improved unit test code coverage to
		- EventType.swift [SDKCF-6378]
		- CustomAttribute.swift [SDKCF-6379]
		- UserInfoProvider.swift [SDKCF-6380]
		- EventMatcher.swift [SDKCF-6390]
		- ConfigurationService.swift [SDKCF-6388]
		- UserDataCache.swift [SDKCF-6384]
		- MessageMixerService.swift [SDKCF-6386]   
		- CampaignRepository.swift [SDKCF-6387]
		- SlideUpViewPresenter.swift [SDKCF-6383]   
		- UILabel+IAM [SDKCF-6385]
		- CommonUtility [SDKCF-6381]
		- Event [SDKCF-6376]
		- AppStartEvent [SDKCF-6376]
		- CustomEvent [SDKCF-6376]
		- PurchaseSuccessfulEvent [SDKCF-6376]
		- LoginSuccessfulEvent [SDKCF-6376]
		- CampaignDispatcher [SDKCF-6452]
		- AlertPresentable [SDKCF-6375]
		- ConfigurationManager [SDKCF-6451]
		- HTTPRequestable [SDKCF-6389]
		- Router [SDKCF-6382]
		- ToolTipView [SDKCF-6377]

### 7.3.0 (2023-01-11)
- Features:
	- Added new API method to close displayed tooltips [SDKCF-6027]
	- Added contexts validation for tooltip campaigns [SDKCF-6028]
	- Added a feature flag to enable/disable the Tooltip feature [SDKCF-6075]
	- Added tracking of opt-in/opt-outs in Push Primer feature [SDKCF-6026]
- Improvements:
	- Restored tab bar items support. Added UITabBar extension method for convenience [SDKCF-6134]
	- Added support for screen orientation changes when using Tooltip feature [SDKCF-6177]
- Bug fixes:
	- Fixed an edge case of not readable status bar when campaign message is displayed [SDKCF-5134]
- Improvements:
	- Sample app improvements

### 7.2.0 (2022-09-23)
- Features:
	- Added Push Primer feature [SDKCF-5631]
	- Added a possibility to set subscription ID and config URL in runtime [SDKCF-5614]
- Improvements:
	- Enable triggers validation for test campaigns [SDKCF-5776]
	- Refactor for Xcode 14 compatibility [SDCFK-5611]
	- Integrated with Emerge Tools [SDKCF-5346]
	- Added a warning when `registerPreference()` is called before `configure()`
- Bug fixes:
	- Fixed Opt-out message visibility on a dark background [SDKCF-5620]
	- Fixed an issue when test campaigns were not displayed [SDKCF-5636]

### 7.1.0 (2022-06-14)
- Improvements:
	- Updated information sent to Analytics [SDKCF-5252]
	- Display impression analytics event is now sent when campaign message appears [SDKCF-5252]
- Bug fixes:
	- Fixed issues with unit tests on Xcode 13.3 [SDKCF-5124]

### 7.0.0 (2022-05-13)
- **Breaking changes:**
	- Aligned public API with Android IAM SDK [SDKCF-4940]
		- `RInAppMessagingDelegate` and `RInAppMessagingErrorDelegate` have been removed.
		- `inAppMessagingShouldShowCampaignWithContexts()` delegate method has been replaced with `onVerifyContext` callback variable..
		- `inAppMessagingDidReturnError()` delegate method has been replaced with `errorCallback` variable.
- Features:
	- Implemented new UX features - Campaigns with no end date, infinite impressions and no ❌ button [SDKCF-5003]
- Improvements:
	- Improved test campaigns handling [SDKCF-5027]
	- Added border in campaign buttons when their color is similar to message body background color [SDKCF-4859]
	- Xcode 13 compatibility
	- Removed Codecov support in favor of SonarQube coverage reports
	- Switched to shared bitrise yaml [file](https://github.com/rakutentech/ios-buildconfig/blob/master/shared-bitrise.yml)
- Bug fixes:
	- Fixed impression counting when application was terminated during campaign display

### 6.1.0 (2022-02-04)
- Improvements:
	- Campaign UI has been updated to be in line with internal Rakuten UI design guide [SDKCF-4471]
	- Added Swift Package Manager (SPM) support [SDKCF-4388]
	- Improved network request error handling [SDKCF-4728] [SDKCF-4637]
	- Added Xcode requirements to README [SDKCF-4790]
	- Integrated SonarQube to track SDK code quality [SDKCF-4693]
- Bug fixes:
	- Custom event attributes are now handled as case insensitive [SDKCF-4550]
	- Fixed test campaign triggers [SDKCF-4525]

### 6.0.0 (2021-11-12)
- **Breaking changes:**
	- The minimum supported OS version is now iOS 12.0 [SDKCF-4361]
	- The `registerPreference()` API method now requires a `UserInfoProvider` object [SDKCF-3970]
	- Removed all Rakuten ID references. The value used as Rakuten ID should be used as the User ID instead. User ID should be treated as any unique member identifier.
- Improvements:
	- Updated user handling to align with the Android IAM SDK. The `registerPreference()` API method now requires a `UserInfoProvider` object, which must be kept up-to-date in your app code. See the README's registerPreference() description. [SDKCF-3970]
	- Added UI tests [SDKCF-2246]
	- Integrated [RSDKUtils](https://github.com/rakutentech/ios-sdkutils) library to replace common code [SDKCF-4351]
	- Updated response models to use non-optionals [SDKCF-4017]
	- Test campaigns are no longer cached.
- Bug fixes:
	- Fixed possible race condition crash in LockableObject [SDKCF-3987]
	- Fixed issue with opt-out logic that occurred on user change [SDKCF-3720]

### 5.0.0 (2021-09-15)
**Breaking change:** Changed public `Identification` enum member `easyId` to `idTrackingIdentifier`.
- Features:
	- Added support for ID tracking identifier. [SDKCF-4072]
- Improvements:
	- Modified AtomicGetSet wrapper to use a concurrent queue with barrier to ensure safe writes.
	- Increased HTTP resource request timeouts to more reasonable values.
	- Added [mobsfscan](https://github.com/MobSF/mobsfscan) automatic code scanning for security issues.
- Bug fixes:
	- Fixed large image display issue in campaigns. [SDKCF-4022]

### 4.0.2 (2021-07-21)
- Improvements:
	- Changed campaigns to not display when attached image cannot be downloaded. [SDKCF-3977]
	- Changed campaigns to not display upon display permission request failure. [SDKCF-3976]
	- Increased clickable area of the IAM close button "x". [SDKCF-3958]
	- Fixed campaign view incorrectly being horizontally scrollable on iPad in landscape orientation [SDKCF-4020]

### 4.0.1 (2021-06-30)
- Improvements:
    - Added recommendation to README that apps should use a remote feature flag to enable/disable the SDK. [SDKCF-3938]

### 4.0.0 (2021-06-22)
**Breaking change:** Config API contract has changed and now requires the v2 GET endpoint. The SDK will not work with the v1 endpoint.
- Improvements:
    - Updated company name references. [SDKCF-3550]
    - Added handling for getConfig response status codes 400 and 404. [SDKCF-3884]
    - Changed Config API call to be a /GET with query params. This allows the backend to filter requests if required. [SDKCF-3652]
    - Added handling for "429 Too Many Requests" response to Config/Ping API requests. When status code 429 is received by the SDK it will start expontential backoff (plus a random factor) retries to space out the requests to the backend. [SDKCF-3654]
    - Campaign opt-out & max impression tracking logic is now handled solely on client side. This change reduces the backend's load per request. [SDKCF-3656]
    - Added support for rollout percentage value received in Config API response. This allows the backend to gradually increase campaign distribution. [SDKCF-3663]
    - Added subscription key in Config API request header to enable better filtering of requests. [SDKCF-3716]
- Bug fixes:
    - Removed canOpenURL check for redirect and deeplink buttons [SDKCF-3848]
    - Fixed rarely occurring threading crashes in dependency manager by using a static queue for access. [SDKCF-3646]

### 3.0.0 (2021-02-10)
**Breaking change:** Minimum supported iOS version is now 11.0 [SDKCF-3182]
- Status bar overlay in Full Screen campaigns is now present in all layout types. The color is adjusted to status bar style (dark or light) - this feature is available only on iOS 13+. [SDKCF-3203, SDKCF-3175]
- Added new API method to close campaign's message manually [SDKCF-3201]
- Improvements:
	- Added integration tests [SDKCF-3109]
	- Moved CI from Travis to Bitrise
	- Improved README [SDKCF-3062, SDKCF-3179]
	- Improved Sample app secrets setup
	- Reduced a chance for user to change screen when campaign is being displayed/animated [SDKCF-3027]
- Bug fixes:
	- Fixed an issue when SDK localization files interfered with host app's localization [SDKCF-3139]
	- Fixed campaign dispatch logic that might have caused an unwanted delay between messages [SDKCF-3007]

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
