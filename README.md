![Build Status](https://app.bitrise.io/app/ffc79d919e1efa04/status.svg?token=xJsKB2zDU77urYIJlqlKZg&branch=master)
[![codecov](https://codecov.io/gh/rakutentech/ios-inappmessaging/branch/master/graph/badge.svg)](https://codecov.io/gh/rakutentech/ios-inappmessaging)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=rakutentech_ios-inappmessaging&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=rakutentech_ios-inappmessaging)

# RInAppMessaging

In-App Messaging (IAM) module allows app developers to easily configure and display notifications within their app.

This module supports iOS 12.0 and above. It has been tested with iOS 12.5 and above.

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

# **Configuring**

**Note:** Currently we do not host any public APIs but you can create your own APIs and configure the SDK to use those.

To use the module you must set the following values in your app's `Info.plist`:

| Key     | Value     |
| :---:   | :---:     |
| `InAppMessagingAppSubscriptionID` | your_subscription_key |
| `InAppMessagingConfigurationURL` | Endpoint for fetching the configuration |


## **Enable and disable the SDK remotely**
We recommend, as good engineering practice, that you integrate with a remote config service so that you can fetch a feature flag, e.g. `Enable_IAM_SDK`, and use its value to dynamically enable/disable the SDK without making an app release. There are many remote config services on the market, both free and paid.

# **Using the SDK**

The SDK provides 3 public methods for the host applications to use:

1. `configure()`
1. `logEvent()`
1. `registerPreference()`
1. `closeMessage()`

### **configure()**  
This method initializes the SDK and should be placed in your AppDelegate's `didFinishLaunchingWithOptions`.

```swift
import RInAppMessaging

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    RInAppMessaging.configure()
    return true
}
```

**Note**: 
* You can wrap the call to `configure()` in an `if <enable IAM-SDK boolean value> == true` condition to control enabling/disabling the SDK. 
* If `configure()` is not called, subsequent calls to other public API SDK functions have no effect.

### **logEvent()**  
This method is provided for the host application to log and save events. These events will be used to match campaign triggers.

**The method signature is:**

```swift
func logEvent(_ event: Event)
```

IAM provides three pre-defined event types and a custom event type:

1.  `AppStartEvent` - This event should be logged when the application is considered started by the host app. E.G AppDelegate's didFinishLaunchingWithOptions. It is persistent, meaning, once it's logged it will always satisfy corresponding trigger in a campaign. All subsequent logs of this event are ignored. Campaigns that require only AppStartEvent are shown once per app launch.
2.  `LoginSuccessfulEvent` - This event should be logged whenever the user logs in successfully.
3.  `PurchaseSuccessfulEvent` - This event should be logged whenever a successful purchase occurs and has several pre-defined properties – purchase amount, number of items, currency code and item list.
4.  `CustomEvent` - This event is created by the host app developers and can take in any event name and a list of custom attributes.

```swift
// App start event.
RInAppMessaging.logEvent(AppStartEvent())
 
// Purchase successful event.
let purchaseEvent = PurchaseSuccessfulEvent()
purchaseEvent.setPurchaseAmount(50)
purchaseEvent.setItemList(["box", "hammer"])
purchaseEvent.setCurrencyCode("USD")

RInAppMessaging.logEvent(purchaseEvent)
 
// Login event.
RInAppMessaging.logEvent(LoginSuccessfulEvent())
 
// Custom event.
let stringAttribute = CustomAttribute(withKeyName: "userResponse", withStringValue: "hi")
let intAttribute = CustomAttribute(withKeyName: "numberOfClicks", withIntValue: 100)
let boolAttribute = CustomAttribute(withKeyName: "didNavigateToPage", withBoolValue: false)
let doubleAttribute = CustomAttribute(withKeyName: "percentageOfCompletion", withDoubleValue: 55.0)
let timeAttribute = CustomAttribute(withKeyName: "timeOfCompletion", withTimeInMilliValue: 32423424)
 
let attributesList = [stringAttribute, intAttribute, boolAttribute, doubleAttribute, timeAttribute]
 
RInAppMessaging.logEvent(CustomEvent(withName: "any_event_name_here", withCustomAttributes: attributesList))
```

### **registerPreference()**

A preference is what will allow IAM to identify users for targeting and segmentation. Preference object should implement `UserInfoProvider` protocol and provide any of the following identifiers (not all need to be provided):

1.  UserID - An unique identifier associated with user membership. Usually it's the name used in login process (e.g. an email address).
1.  IDTrackingIdentifier - The value provided by the internal ID SDK as the "tracking identifier" value.
1.  AccessToken - This is the token provided by the internal RAuthentication SDK as the "accessToken" value

The preference object can be set once per app session. IAM SDK will read object's properties on demand.

To help IAM identify users, please keep user information in the preference object up to date.
After logout is complete please ensure that all `UserInfoProvider` methods in the preference object return `nil`.  
Preferences are not persisted so this function needs to be called on every launch.

#### Generic example using UserID

```swift
import RInAppMessaging

class UserPreference: UserInfoProvider {
    func getUserID() -> String? { 
        "member-id" 
    }

    func getIDTrackingIdentifier() -> String? { nil }
    func getAccessToken() -> String? { nil }
}

let preference = UserPreference()
RInAppMessaging.registerPreference(preference)
```


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


## **Custom Events**

As shown in the example above for event logging, IAM also supports custom event. Custom events are events with an unique name and a list of attributes associated with them.

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

From the SDK side, host app developers will be able to log custom events as shown in the examples above. When the event matching process happens, note that the attributes of the event logged by the host app will be compared against the campaign's trigger attribute value e.g. if the trigger attribute value is an integer of 5 with an operator type of `GREATER_THAN`, and the attribute value of the event logged is an integer 10, then the 10 will be successfully matched against the 5 with a `GREATER_THAN` operator (i.e. 10 > 5).


## **Optional features**

### **RInAppMessagingDelegate**

An optional delegate. Set the `RInAppMessaging.delegate` and implement the protocol method `inAppMessagingShouldShowCampaignWithContexts(contexts:campaignTitle:)` in order to be called before a message is displayed when a campaign title contains one or more contexts. A context is defined as the text inside "[]" within an IAM portal "Campaign Name" e.g. the campaign name is "[ctx1] title" so the context is "ctx1".

```swift
func inAppMessagingShouldShowCampaignWithContexts(contexts: [String], campaignTitle: String) -> Bool {
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

### **RInAppMessagingErrorDelegate**

An optional error delegate. Set the `RInAppMessaging.errorDelegate` and implement the protocol method `inAppMessagingDidReturnError(error:)` to receive an `NSError` object whenever an internal SDK error occurs. This allows you to log the errors somewhere, e.g. a 3rd party analytics service, for later troubleshooting.

### **(BOOL)accessibilityCompatibleDisplay**  

This flag can be used to support UI test automation tools like Appium. When set to `true`, the SDK will use a different display method which changes campaign messages' view hierarchy. This can solve issues with accessibility tools having problems detecting visible items.
 __Note__: There is a possibility that changing this flag will cause campaigns to display incorrectly.

```swift
import RInAppMessaging

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    RInAppMessaging.accessibilityCompatibleDisplay = true
    return true
}
```

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
$ fc-scan customfont-medium.otf --format "%{postscriptname}\n"

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

#### For other issues and more detailed information, Rakuten developers should refer to the Troubleshooting Guide on the internal developer documentation portal.
