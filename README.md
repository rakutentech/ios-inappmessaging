![Build Status](https://app.bitrise.io/app/ffc79d919e1efa04/status.svg?token=xJsKB2zDU77urYIJlqlKZg&branch=master)
[![codecov](https://codecov.io/gh/rakutentech/ios-inappmessaging/branch/master/graph/badge.svg)](https://codecov.io/gh/rakutentech/ios-inappmessaging)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=rakutentech_ios-inappmessaging&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=rakutentech_ios-inappmessaging)

# RInAppMessaging

In-App Messaging (IAM) module allows app developers to easily configure and display notifications within their app.

This module supports iOS 12.0 and above. It has been tested with iOS 12.5 and above.

### This page covers:
* [Requirements](#requirements)
* [How to install](#how-to-install)
* [Configuration](#configuration)
* [Using the SDK](#using-the-sdk)
* [Final Code (Sample)](#final-code)
* [Advanced Features](#advanced-features)
* [SDK Logic](#sdk-logic)
* [Troubleshooting & F.A.Q.](#troubleshooting--faq)
  
# Requirements

Xcode >= 14.1 is supported.

Swift >= 5.7.1 is supported.

Note: The SDK may build on earlier Xcode versions but it is not officially supported or tested.

# **How to install**

RInAppMessaging SDK is distributed as a Cocoapod and as a Swift Package.

## CocoaPods
More information on installing pods: [https://guides.cocoapods.org/using/getting-started.html](https://guides.cocoapods.org/using/getting-started.html)

1. Include the following in your application's Podfile

```ruby
pod 'RInAppMessaging'
```
**Note:** RInAppMessaging SDK requires `use_frameworks!` to be present in the Podfile.

2. Run the following in the terminal

```
pod install
```

## Swift Package Manager
Open your project settings in Xcode and add a new package in 'Swift Packages' tab:
* Repository URL: `https://github.com/rakutentech/ios-inappmessaging.git`
* Version settings: 6.1.0 "Up to Next Major" (6.1.0 is the first version to support SPM)

Choose `RInAppMessaging` product for your target. If you want to link other targets, go to Build Phases of that target, then in Link Binary With Libraries click + button and add `RInAppMessaging`.

# **Configuration**

**Note:** Currently we do not host any public APIs but you can create your own APIs and configure the SDK to use those.

To use the module you must set your app's subscription key and a config endpoint URL using one of the provided methods:

### Build-time configuration<a name="build-time-config"></a>
Add the following entries in your app's `Info.plist`:

| Key     | Value     |
| :---:   | :---:     |
| `InAppMessagingAppSubscriptionID` | your\_subscription\_key |
| `InAppMessagingConfigurationURL` | Endpoint for fetching the configuration |

### Runtime configuration
Provide a value for `subscriptionID` and `configurationURL` parameters when calling `RInAppMessaging.configure` method. 
```swift
RInAppMessaging.configure(subscriptionID: "your_subscription_key",
                          configurationURL: "Endpoint for fetching the configuration")
```

⚠️ The runtime configuration values take precedence over build-time configuration.

## **Enable and disable the SDK remotely**
We recommend, as good engineering practice, that you integrate with a remote config service so that you can fetch a feature flag, e.g. `Enable_IAM_SDK`, and use its value to dynamically enable/disable the SDK without making an app release. There are many remote config services on the market, both free and paid.

# **Using the SDK**

The SDK provides 3 public methods for the host applications to use:

1. `configure()`
1. `registerPreference()`
1. `logEvent()`
1. `closeMessage()`

**Please refer to the [Troubleshooting & F.A.Q](#troubleshooting--faq) section for additional details on configuring and using IAM sdk**

### **1. configure()**  
This method initializes the SDK and should be placed in your AppDelegate's `didFinishLaunchingWithOptions`.

```swift
import RInAppMessaging

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    RInAppMessaging.configure(subscriptionID: "runtime-config-subscription-id",
                              configurationURL: "runtime.config.url")
    return true
}
```

**Note**: 
* `subscriptionID` and `configurationURL` parameters are optional if you set their values in Info.plist (See [build-time configuration](#build-time-config))
* You can wrap the call to `configure()` in an `if <enable IAM-SDK boolean value> == true` condition to control enabling/disabling the SDK. 
* If `configure()` is not called, subsequent calls to other public API SDK get retained and get triggered after `configure()` is called.
* If RMC SDK is used for installing IAM SDK then RMC SDK configuration should be followed rather than IAM configuration.

### <a name="register-preference"></a>2. registerPreference()

A preference is what will allow IAM to identify users for targeting and segmentation. Preference object should implement `UserInfoProvider` protocol and provide any of the following identifiers (not all need to be provided):

1.  UserID - An unique identifier associated with user membership. Usually it's the name used in login process (e.g. an email address).
1.  IDTrackingIdentifier - The value provided by the internal ID SDK as the "tracking identifier" value.
1.  AccessToken - This is the token provided by the internal RAuthentication SDK as the "accessToken" value

⚠️ The method is designed to be called ONCE once per app session - i.e. only one instance of `UserInfoProvider` can be created. IAM SDK will read object's properties on demand. There's no need to call this method again after login/logout for example.

To ensure correct user targeting, please keep user information in the preference object up to date.
After logout process is complete the preference object should return `nil` or `""` in all `UserInfoProvider` methods.  
Preferences are not persisted so this function needs to be called on every launch.

#### Generic example using UserID

```swift
import RInAppMessaging

class UserPreference: UserInfoProvider {
    func getUserID() -> String? { 
        "member-id" 
    }

    func getIDTrackingIdentifier() -> String? {
        "easy id"
    }
    func getAccessToken() -> String? {
        "access token" 
  }
}

let preference = UserPreference()
RInAppMessaging.registerPreference(preference)
```

You must provide the relevant information through this class. It will be retrieved by SDK on demand, so make sure values are up-to-date.

After logout is complete, please ensure that all `UserInfoProvider` methods in the preference object return `null` or empty string.

> Notes:
> - Regarding access token:
>   - Only provide access token if the user is logged in
>   - The internal Backend only supports production access token
> - Migrating from legacy Mobile Login SDK to ID SDK
>   - Update your `UserInfoProvider` and return valid value for the `getIDTrackingIdentifier()` method. Do not provide values for other methods or leave them as null or empty.
>   - **Impact**: User will be treated as a new user, therefore if there are **active** messages that were previously displayed/opted-out by the user, then it will be displayed again


### **3. logEvent()**  
This method is provided for the host application to log and save events. These events will be used to match campaign triggers which initiates the display of a message whenever a specific event or a set of events occur. Call this method at appropriate locations in your app, and based on your use-case.

For each logged event, the SDK will match it with the ongoing message's triggers that are configured in the Dashboard. Once all of the required events are logged by the app, the message will be displayed in the current registered activity. If no activity is registered, it will be displayed in the next registered activity.

**The method signature is:**

```swift
func logEvent(_ event: Event)
```
#### Pre-defined event classes:

IAM provides three pre-defined event types and a custom event type:
1.  `AppStartEvent`
2.  `LoginSuccessfulEvent` 
3.  `PurchaseSuccessfulEvent`
4.  `CustomEvent`

#### AppStartEvent
Log this event on app launch from terminated state.

This event should be logged when the application is considered started by the host app. E.G AppDelegate's didFinishLaunchingWithOptions. It is persistent, meaning, once it's logged it will always satisfy corresponding trigger in a campaign. All subsequent logs of this event are ignored. Campaigns that require only AppStartEvent are shown once per app launch

```swift
// App start event.
RInAppMessaging.logEvent(AppStartEvent())
```

> <font color="red">Note:</font>
> Because this event is logged almost instantly after app launch, there may be situation wherein user information is not yet available due to some delay, and may cause unexpected behavior. Therefore we recommend to ensure user information is up-to-date (see [User Targeting](#register-preference) section for details) when using AppStart-only as trigger, or combine it with other event wherein user information is guaranteed to be available.

#### LoginSuccessfulEvent
Log this every time the user logs in successfully.

```swift
// Login event.
RInAppMessaging.logEvent(LoginSuccessfulEvent())
```

#### PurchaseSuccessfulEvent
This event should be logged whenever a successful purchase occurs and has several pre-defined properties – purchase amount, number of items, currency code and item list.

```swift
// Purchase successful event.
let purchaseEvent = PurchaseSuccessfulEvent()
purchaseEvent.setPurchaseAmount(50)
purchaseEvent.setItemList(["box", "hammer"])
purchaseEvent.setCurrencyCode("USD")

RInAppMessaging.logEvent(purchaseEvent)
```

### 4. CustomEvent
This event is created by the host app developers and can take in any event name and a list of custom attributes. Log this after app-defined states are reached or conditions are met. Example use-case is an event based on tabs or certain screens in your app.

Custom events are events with an unique name and a list of attributes associated with them. Attributes can be `integer`, `double`, `String`, `boolean`, or `Date` type.

* Every custom event requires a name(case insensitive), but doesn't require to add any attributes with the custom event.
* Each custom event attribute also requires a name(case insensitive), and a value.
* Recommended to use English characters only.
* Because the custom event's name will be used when matching messages with triggers; therefore, please make sure the actual message event's name and attribute's name must match with the logged events to SDK.

**Additional Information regarding Custom Event:**
<details>
<summary style="cursor: pointer;";>(click to expand)</summary>
In order to properly utilize custom events, the person creating the campaign must sync up with the host app developers to ensure that both the event name and attribute name/value exactly match exactly - note that these are case-sensitive.

From the dashboard side, you will have the ability to also add an operator. The following operators are supported:  
1) `EQUALS` - The values should be equal. In terms of timeInMillis, there will be a tolerance of 1000 milliseconds. E.G 1001 and 500 milliseconds will be considered equal.  
2) `IS_NOT_EQUAL` - The values should be different. In terms of timeInMillis, there will be a tolerance of 1000 milliseconds. E.G 1001 and 500 milliseconds will be considered equal.  
3) `GREATER_THAN` - The event attribute value is greater than the campaign's trigger value. Applies to only arithmetic types.  
4) `LESS_THAN` - The event attribute value is less than the campaign's trigger value. Applies to only arithmetic types.  
5) `IS_BLANK` - The attribute value is empty. Applies to only String type only.  
6) `IS_NOT_BLANK` - The attribute value is not empty. Applied to String type only.  
7) `MATCHES_REGEX` - The attribute value matches the regular expression. Applies to only String type.  
8) `DOES_NOT_MATCH_REGEX` - The attribute value does not match the regular expression. Applies to only String type string.

*Note:* When comparing date as timeInMillis values, there is a tolerance of 1000 milliseconds. This means that comparisons using any relevant operator types will have a leniency of 1 second. E.g. comparing 300ms and 600ms with the `EQUALS` operator will return `true`, while comparing 300 and 1400 will return `false`.

From the SDK side, host app developers will be able to log custom events as shown in the examples below. When the event matching process happens, note that the attributes of the event logged by the host app will be compared against the campaign's trigger attribute value e.g. if the trigger attribute value is an integer of 5 with an operator type of `GREATER_THAN`, and the attribute value of the event logged is an integer 10, then the 10 will be successfully matched against the 5 with a `GREATER_THAN` operator (i.e. 10 > 5).


```swift
// Custom event.
let stringAttribute = CustomAttribute(withKeyName: "userResponse", withStringValue: "hi")
let intAttribute = CustomAttribute(withKeyName: "numberOfClicks", withIntValue: 100)
let boolAttribute = CustomAttribute(withKeyName: "didNavigateToPage", withBoolValue: false)
let doubleAttribute = CustomAttribute(withKeyName: "percentageOfCompletion", withDoubleValue: 55.0)
let timeAttribute = CustomAttribute(withKeyName: "timeOfCompletion", withTimeInMilliValue: 32423424)
 
let attributesList = [stringAttribute, intAttribute, boolAttribute, doubleAttribute, timeAttribute]
 
RInAppMessaging.logEvent(CustomEvent(withName: "any_event_name_here", withCustomAttributes: attributesList))
```
</details>

### **closeMessage()**

In certain cases there might be a need to manually close a campaign's message without user interaction.
An example is when a different user logs in and the currently displayed campaign does not target the new user.
(Or when a campaign's message appears after login process has started).
In that case, to avoid user's confusion, host app can force-close the campaign by calling `closeMessage()` API method.
The `clearQueuedCampaigns` optional parameter, when set to `true` (`false` by default), will additionally remove all campaigns that were queued to be displayed.

```swift
RInAppMessaging.closeMessage(clearQueuedCampaigns: true)
```
**Note:** Calling this API will not increment the campaign's impression (i.e. not counted as displayed).

## <a name="final-code"></a>Final Code (Sample)

**For reference, your SDK integration code should look something like this:**

<details>
<summary style="cursor: pointer;";>(click to expand)</summary>

AppDelegate.swift
```swift
import RInAppMessaging

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    RInAppMessaging.configure(subscriptionID: "subscriptionID", 
                                configurationURL: "configURL",
                                enableTooltipFeature: true)
    RInAppMessaging.registerPreference(self.preferenceData)
    return true
}
```


IAMPreferenceData.swift
```swift
import RInAppMessaging

class IAMPreferenceData: UserInfoProvider {
    var userID: String?
    var easyID: String?
    var accessToken: String?

}

extension IAMPreferenceData {
    func getAccessToken() -> String? {
        "accessToken"
    }

    func getUserID() -> String? {
         "userID"
    }

    func getIDTrackingIdentifier() -> String? {
        "easyID"
    }
}
```


ViewController.swift
```swift
class ViewController: UIViewController {
    var preferenceData = IAMPreferenceData()

    override func viewDidLoad() {
        RInAppMessaging.logEvent(AppStartEvent())
    }

    func onUserLogin() {
        preferenceData.userId = "<userId>"
        preferenceData.accessToken = "<accessToken>" // or idTracking
        RInAppMessaging.logEvent(LoginSuccessfulEvent())
    }
    
    fun onUserLogout() {
        preferenceData.userId = ""
        preferenceData.accessToken = "" // or idTracking
    }
}
```
</details>

## **Advanced Features**

### **Campaign context verification**

An optional variable `onVerifyContext` is called before a message is displayed for campaigns that have one or more contexts defined. A context can be added as the text inside "[]" within an IAM portal "Campaign Name" e.g. the campaign name is "[ctx1] title" so the context is "ctx1". Return `false` in `onVerifyContext` closure to prevent campaign from displaying (it won't count as an impression).<br/>
__Note__: `onVerifyContext` is not called for campaigns without defined contexts.<br/>
__Note__: This feature also works with Tooltips. ('[Tooltip]' in the title is not considered as a context)

```swift
RInAppMessaging.onVerifyContext = { (contexts: [String], campaignTitle: String) in
    guard campaignTitle == "[context1] campaign-title-1", contexts.contains("context1") else {
        return true
    }
    if /* check your condition e.g. are you on the correct screen to display this message? */ {
        return true
    } else {
        return false
    }
}
```

### **Error callback**

Developers can set an optional variable `errorCallback` to receive internal SDK errors. This allows you to log the errors somewhere, e.g. a 3rd party analytics service, for later troubleshooting.
```swift
import RInAppMessaging

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    RInAppMessaging.errorCallback = { [weak self] error in
        self?.logger.log(error.description)
    }
}
```

### **Accessibility / Automation tests support**  

The campaign message view contains elements with `accessibilityIdentifier` value. In some apps those elements might not visible for test automation tools like Appium. To fix that issue set `accessibilityCompatibleDisplay` flag to `true`. The SDK will use a different logic to display campaign messages.<br/>
__Note__: This feature changes the way campaign views are added to the view hierarchy which, in some apps, might result in campaigns to be displayed incorrectly.

```swift
import RInAppMessaging

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    RInAppMessaging.accessibilityCompatibleDisplay = true
    return true
}
```

### **Push Primer**  [Under Construction]
Push Primer is a special action type that can be set in ONE of the campaign message buttons.
When user taps the Push Primer button, the SDK tries to authorize and then register for remote notifications.
Developers can set `UNUserAuthorizationOptions` used during authorization proces by setting `pushPrimerAuthorizationOptions` variable:

```swift
RInAppMessaging.pushPrimerAuthorizationOptions = [.badge, .provisional]
```

If the variable wasn't modified, a default value will be used.

⚠️ The Push Primer feature will not work if user has disabled Remote Notifications in system settings.

Errors related to authorization requests can be accessed using the 'Error callback' feature.
Errors related to registration requests will be returned in `application(_:didFailToRegisterForRemoteNotificationsWithError:)` method in the App delegate object.
The process can be considered as successful when `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` method is called.

[How to set up your app for registering with APNS](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns)

### **Tooltip Campaigns**
Tooltip feature is currently in beta testing; its features and behaviour might change in the future.
Please refer to the internal guide for more information.

To enable tooltips you must set `enableTooltipFeature` flag to true when calling `configure()`
```swift
RInAppMessaging.configure(enableTooltipFeature: true)
```
##### UIKit:
To attach tooltip to a UIView instance, set its `accessibilityIdentifier` value to tooltip's `UIElement` identifier.
```swift
let actionButton = UIButton()
actionButton.accessibilityIdentifier = "tooltip.1"
```
##### SwiftUI:
To attach tooltip to a SwiftUI view, use `canHaveTooltip()` modifier.  
**Important:** This modifier must be called AFTER `RInAppMessaging.configure()`. Otherwise the tooltip will not appear.
```swift
import RInAppMessaging
(...)
var body: some View {
    Button("Action")
        .canHaveTooltip(identifier: "tooltip.1")
}
```
**Note:** This feature requires minimum iOS version of 15.0

#### **Displaying Tooltips on tab bar buttons**
(Applicable only to UIKit integration)  
To be able to display tooltips on UITabBar items/buttons you need to set `accessibilityIdentifier` of UITabBarItem object associated with your tab view controller. Then you need to call `updateItemIdentifiers()` method on `UITabBar` object.

A code example from UIViewController's `viewDidLoad()` method
```swift
tabBarItem.accessibilityIdentifier = "UIElement.4"
tabBarController?.tabBar.updateItemIdentifiers()
```
This setup can be also done in other lifecycle methods and classes.

#### **Manually closing displayed tooltip**
Tooltips can be closed manually in similar way campaign messages are closed with `closeMessage()` API method.<br/>
The `closeTooltip(with uiElementIdentifier: String)` API method closes currently displayed tooltip attached to provided UI Element without user interaction. The `uiElementIdentifier` parameter identifier tells SDK which tooltip should be closed. Its value should match the value put under `UIElement` parameter in tooltip JSON payload.

```swift
RInAppMessaging.closeTooltip(with: "uielement.button.action1")
```
**Note:** Calling this method will not count as an impression (i.e. the message won't be counted as displayed). 


## **Build/Run Example Application and Unit Tests**

* Clone or fork the repo
* `cd` to the repo folder
* Set env vars `RIAM_CONFIG_URL` and `RIAM_APP_SUBSCRIPTION_KEY` according to the internal integration guide
* _Important Note_: `InAppMessaging-Secrets.xcconfig` **MUST NOT** be committed to git - it is ignored by git in the repo's `.gitignore` file
* Run `bundle install` then run `bundle exec pod install`
* Open `RInAppMessaging.xcworkspace` in Xcode then build/run
* To run the tests press key shortcut command-U

# **SDK Logic**

## User cache

Each user has a separate cache container that is persisted in UserDefaults. Each combination of userId and idTrackingIdentifier is treated as a different user including a special - anonymous user - that represents non logged-in user (userId and idTrackingIdentifier are null or empty).
The cache stores data from ping response enriched with impressions counter and opt-out status.
Calling `registerPerference()` reloads the cache and refreshes the list of available campaigns (with ping request).

## Client-side opt-out handling

If user (with registered identifier using `registerPerference()`) opts out from a campaign, that information is saved in user cache locally on the device and the campaign won't be shown again for that user on the same device. The opt-out status is not shared between devices. The same applies for anonymous user.

## Client-side max impressions handling

Campaign impressions (displays) are counted locally for each user. Meaning that a campaign with maxImpression value of 3 will be displayed to each user (registered with `registerPerference()`) max 3 times. Campaign's max impression number can be modified in the dashboard/backend. Then the SDK, after next ping call, will compare new value with old max impression number and add the difference to the current impression counter. The max impression data is not shared between devices. The same applies for anonymous user.

## (Optional) How enable custom fonts in your Campaigns

The SDK will optionally use custom fonts in your Campaigns if your app has them pre-registered. Specify one for the text body/headers and one for the buttons in either `ttf` or `otf` format. Fallsback to the system font if unset.

First add the two font files to your Xcode target.

Get the "PostScript name" of your fonts by:

```bash
$ fc-scan --format "%{postscriptname}\n" customfont-medium.otf

AdventPro-Medium
```

In your `Info.plist` configuration, set the PostScript names under `InAppMessagingCustomFontNameTitle`, `InAppMessagingCustomFontNameText` and `InAppMessagingCustomFontNameButton` along with the file names of the fonts under `UIAppFonts`.

```xml
<key>InAppMessagingCustomFontNameTitle</key>
<string>AdventPro-Bold</string>
<key>InAppMessagingCustomFontNameText</key>
<string>AdventPro-Regular</string>
<key>InAppMessagingCustomFontNameButton</key>
<string>AdventPro-Medium</string>

<key>UIAppFonts</key>
<array>
    <string>customfont-bold.otf</string>
    <string>customfont-regular.otf</string>
    <string>customfont-medium.otf</string>
</array>
```

# **Troubleshooting & F.A.Q.**

* Configuration service returns `RequestError.missingMetadata` error
  * Ensure that IAM SDK is integrated properly (not as a static library)
* If you receive HTTP error 401
  * If you are providing an access token in `UserInfoProvider` make sure that it comes from PROD endpoint. (this applies only to Rakuten developers)
* If user targeting is not working
  * Ensure you provide *userId* or *idTrackingIdentifier* in `UserInfoProvider` object.
  * If you set an *accessToken* you **must also** provide associated *userId*. (Rakuten developers only)
  * Ensure you are not providing *accessToken* and *idTrackingIdentifier* at the same time. (Rakuten developers only)
  * IAM SDK is not able to verify if provided accessToken is invalid or not matching userId.
* Status bar characters and icons are not visible when Full-Screen campaign is presented
  * If your app is running on iOS version below 13.0 you need to either change background color of the campaign or set proper `preferredStatusbarStyle` in the top-most view controller. (for iOS versions above 13.0 this issue is handled internally by the SDK)
* A launch event campaign is presented more times than expected.
  * Ideally `registerPreference()` should be called after `configure()` and before any `logEvent()` method
  * The preference object must contain up-to-date information before `registerPreference()` is called
  * Each *userId*/*idTrackingIdentifier* combination (including empty one) has its own counter for campaign impressions.
  * Killing the app or calling `closeMessage()` API while campaign is being displayed doesn't count as impression.
  **Note:** If `registerPreference()` is called before `configure()` then it gets retained and gets triggered after `configure()` is called. 

#### For other issues and more detailed information, Rakuten developers should refer to the Troubleshooting Guide on the internal developer documentation portal.
