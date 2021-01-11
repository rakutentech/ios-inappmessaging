[![Build Status](https://app.bitrise.io/app/ffc79d919e1efa04/status.svg?token=xJsKB2zDU77urYIJlqlKZg&branch=master)]
[![codecov](https://codecov.io/gh/rakutentech/ios-inappmessaging/branch/master/graph/badge.svg)](https://codecov.io/gh/rakutentech/ios-inappmessaging)


# RInAppMessaging

In-App Messaging (IAM) module allows app developers to easily configure and display notifications within their app.

⚠️ This module supports iOS 10.0 and above in line with internal GMD recommendations. It has been tested with iOS 11.0 and above.

# **How to install**

RInAppMessaging SDK is distributed as a Cocoapod.  
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

# **Configuring**

**Note:** Currently we do not host any public APIs but you can create your own APIs and configure the SDK to use those.

To use the module you must set the following values in your app's `Info.plist`:

| Key     | Value     |
| :---:   | :---:     |
| `InAppMessagingAppSubscriptionID` | your_subscription_key |
| `InAppMessagingConfigurationURL` | Endpoint for fetching the configuration |


# **Using the SDK**

The SDK provides 3 public methods for the host applications to use:

1. `configure()`
2. `logEvent()`
3. `registerPreference()`

### **configure()**  
This method is called to initialize the SDK and should be placed in your AppDelegate's `didFinishLaunchingWithOptions`.

```swift
import RInAppMessaging

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    RInAppMessaging.configure()
    return true
}
```

### **logEvent()**  
This method is provided for the host application to log and save events. These events will be used to match campaign triggers.

**The method signature is**

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
 
let attriList = [stringAttribute, intAttribute, boolAttribute, doubleAttribute, timeAttribute]
 
RInAppMessaging.logEvent(CustomEvent(withName: "any_event_name_here", withCustomAttributes: attriList))
```

### **registerPreference()**

A preference is what will allow IAM to identify users for targeting and segmentation. At the moment, IAM will take in any of the following identifiers:

1.  RakutenID
2.  UserID - The ID when registering a Rakuten account. e.g. an email address
3.  AccessToken - This is the token provided by the internal RAuthentication SDK as the "accessToken" value

To help IAM identify users, please set a new preference every time a user changes their login state i.e. when they log in or log out.  
After logout is complete please call  `registerPreference()` with nil parameter.  
Not all identifiers have to be provided*.  
**NOTE**: *For our internal users - for user targeting you must provide an accessToken. If you are setting an accessToken you must also provide associated userId in `IAMPreference`.

```swift
let preference = IAMPreferenceBuilder()
    .setUserId("testaccount@gmail.com")
    .setRakutenId("testaccount")
    .setAccessToken("27364827346")
    .build()

RInAppMessaging.registerPreference(preference)
```

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

*Note:* When comparing date as timeInMillis values, there will be a tolerance of 1000 milliseconds. This means that comparisons using any relevant operator types will have a leniency of 1 second e.g. comparing 300ms and 600ms with the `EQUALS` operator will return `true` and comparing 300 and 1400 will return `false`.

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
* _Important Note_: `Example-Secrets.xcconfig` **MUST NOT** be committed to git - it is ignored by git in the repo's `.gitignore` file
* Run `bundle install` then run `bundle exec pod install`
* Open `RInAppMessaging.xcworkspace` in Xcode then build/run
* To run the tests press key shortcut command-U

## **Troubleshooting**

* Rakuten developers experiencing problems should refer to the Troubleshooting Guide on the internal developer documentation portal.
