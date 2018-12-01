# LocalNotificationScheduler

# Introduction
LocalNotificationScheduler is an easier method to schedule local notifications in your project. It can schedule different types of local notifocations with one line of code. 

# Requirements
- Swift 4.2+
- iOS 10.0+ 
- Xcode 9.0+
# Installation

**CocoaPods**

LocalNotificationScheduler is available  through CocoaPods. To install it, simply add the following line to your Podfile:
```pod
pod 'LocalNotificationScheduler'
```
and import the library in a page where you use 
```swift
import LocalNotificationScheduler
```

# Usage
LocalNotificationScheduler provided three methods to schedule notifications. Every method has an optional completion handler that returns error if there was any problem in scheduling notifications. Error can be notifications permissions error in case of normal notifications or location permissions error incase of region monitoring notifications.


To schedule notifications you can use shared instance:
```swift
NotificationScheduler.shared
```
or create your own instance if you want to handle delegate methods yourself
```swift
let scheduler = NotificationScheduler(withDelegate: self)
```

**Schedule Calendar Notifications**

- Below method can be used to fire notification at some specific date time. 
- User can set notification with only date, repeating, identifier and title. 

```swift
let date = NSDate().addingTimeInterval(100)
NotificationScheduler.shared.scheduleNotificationWithFireDate(date as Date, repeatInterval:.hour, identifier: "hourly_repeating", title: "Hours Repeat")
```
- Or user can use some/all parameters to schedule notifications. Most parametes are optional so can be skipped from the function.

```swift
import UserNotifications

NotificationScheduler.shared.scheduleNotificationWithFireDate(date as Date, repeatInterval: .month, identifier: "monthly_repeating", title: "This notification repeats every month", subTitle: "This notification repeats every month", body: "This notification repeats every month", badge: NSNumber(value: 10), categoryIdentifier: "categortOne", threadIdentifier: "threadOne", launchImageName: nil, sound: UNNotificationSound.default, userInfo: ["paramOne": 10], attachments: []) { (error) in

}
```

**Schedule Time Interval Notifications**

- This method can be used to schedule notifications that fire after specific time interval in seconds.

```swift
NotificationScheduler.shared.scheduleNotificationWithTimeInterval(200, repeats: true, identifier: "time_interval", title: "This notification fires after 200 seconds.", subTitle: "This notification fires after 200 seconds.", completion: { error in
print(error)
})
})
```

**Schedule Region Monitoring Notifications**

- Before scheduling any notifications using this method, your app must have authorization to use Core Location and must have when-in-use permissions. If you don't have location authorization then this method will throw an error.
- This method can be used to schedule notifications that monitor circular region.


```swift
import CoreLocation

let toBeMonitoredRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(48.424080, -123.363826), radius: 1000, identifier: "home")
toBeMonitoredRegion.notifyOnExit = true
toBeMonitoredRegion.notifyOnEntry = true
NotificationScheduler.shared.scheduleNotificationWithRegion(toBeMonitoredRegion, repeats: true, identifier: "region_home", title: "You have entered/exited your home")
```



## Author

harishchopra86, harish@freshworks.io, harishchopra86@gmail.com

## License

LocalNotificationScheduler is available under the MIT license. See the LICENSE file for more info.
