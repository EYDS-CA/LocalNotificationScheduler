 //
 //  NotificationScheduler.swift
 //
 //  Created by Harish Chopra on 2018-12-01.
 //
 
 import Foundation
 import UserNotifications
 import CoreLocation
 
 let MAXIMUM_ALLOWED_NOTIFICATIONS = 64 // We can to manually keep track for the scheduled notifications
 
 @available(iOS 10.0, *)
 public class NotificationScheduler: NSObject {
    
    public typealias NotificationAuthorizationCompletionHandler = (_ allowed: Bool, _ authorizationStatus: UNAuthorizationStatus) -> Void
    public typealias NotificationActionCompletionHandler = (_ error: Error?) -> Void
    
    //MARK: Use shared to schedule notifications if you don't want to handle notification delegates. If you want to handle delegates then create an instance of this class to schedule notifications.
    public static var shared = NotificationScheduler()
    
    let notificationCenter = UNUserNotificationCenter.current()
    var authorizationOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
    private var pendingHandlers = [NotificationAuthorizationCompletionHandler]()
    
    public var scheduledNotificationsCount: Int {
        let waitSemaphore = DispatchSemaphore(value: 0)
        var count: Int = 0
        
        let center: UNUserNotificationCenter = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            count = requests.count
            waitSemaphore.signal()
        }
        
        let _ = waitSemaphore.wait(timeout: DispatchTime.distantFuture)
        return count
    }
    
    public init(withDelegate delegate: UNUserNotificationCenterDelegate? = nil) {
        super.init()
        delegate == nil ? notificationCenter.delegate = self : ()
    }
    
    private func requestForPermissions(_ completionHandler: @escaping NotificationAuthorizationCompletionHandler) {
        notificationCenter.requestAuthorization(options: authorizationOptions) { (granted, error) in
            guard granted else {
                return completionHandler(false, .denied)
            }
            self.getSettings({ (allowed, status) in
                return completionHandler(allowed, status)
            })
        }
    }
    
    //MARK: Thos method is called before scheduling every notificationa and if user have not provided permissions then error is thrown. This method can also be called explicitely to check if app has permissions.
    public func checkNotificationSettings(_ completionHandler: @escaping NotificationAuthorizationCompletionHandler) {
        self.pendingHandlers.append(completionHandler)
        guard pendingHandlers.count == 1 else {
            return
        }
        self.getSettings { (allowed, status) in
            self.handleNotificationSettings(isAllowed: allowed, authorisationStatus: status)
        }
    }
    
    private func getSettings(_ completionHandler: @escaping NotificationAuthorizationCompletionHandler) {
        notificationCenter.getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .notDetermined:
                return self.requestForPermissions({ (allowed, status) in
                    completionHandler(allowed, status)
                })
            case .denied:
                return completionHandler(false, .denied)
            case .authorized:
                return completionHandler(true, .authorized)
            case .provisional:
                if #available(iOS 12.0, *) {
                    return completionHandler(true, .provisional)
                }
            }
        }
    }
    
    private func handleNotificationSettings(isAllowed: Bool, authorisationStatus: UNAuthorizationStatus) {
        let handlers = self.pendingHandlers
        self.pendingHandlers = []
        handlers.forEach({$0(isAllowed, authorisationStatus)})
    }
    
    public func printPendingNotification() {
        notificationCenter.getPendingNotificationRequests(completionHandler: { (notifications) in
            print(notifications.count)
        })
    }
    
    //MARK: This method cancels all scheduled notification and if identifier is provided then this method cancels all scheduled notifications with provided identifiers.
    public func cancelAllNotifications(withIdentifiers identifiers: [String]? = nil, completion: NotificationActionCompletionHandler? = nil) {        
        self.checkNotificationSettings { (allowed, _) in
            if allowed {
                identifiers == nil ? self.notificationCenter.removeAllPendingNotificationRequests() : self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers ?? [])
                completion?(nil)
            }
            else {
                completion?(self.getNotificationPermissionsError)
            }
        }
    }
    
    //MARK: This method can be used to schedule region monitoring local notification. Before scheduling any notifications using this method, your app must have authorization to use Core Location and must have when-in-use permissions. If you don't have location authorization then this method will throw an error.
    public func scheduleNotificationWithRegion(_ region: CLCircularRegion, repeats: Bool, identifier: String, title: String, subTitle: String = "", body: String = "", badge: NSNumber? = 0, categoryIdentifier: String? = nil, threadIdentifier: String? = nil, launchImageName: String? = nil, sound: UNNotificationSound? = nil, userInfo: [AnyHashable : Any]? = nil, attachments: [UNNotificationAttachment]? = nil, completion: NotificationActionCompletionHandler? = nil) {
        
        if scheduledNotificationsCount >= MAXIMUM_ALLOWED_NOTIFICATIONS {
            completion?(getNotificationCountError)
            return
        }
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .restricted, .denied:
            completion?(getLocationAuthorizationError)
            return
        case .authorizedAlways, .authorizedWhenInUse:
            break
        }
        
        self.checkNotificationSettings { (allowed, _) in
            if allowed {
                scheduleWithRegion(region, repeats: repeats, identifier: identifier, title: title, subTitle: subTitle, body: body, badge: badge, categoryIdentifier: categoryIdentifier, threadIdentifier: threadIdentifier, launchImageName: launchImageName, sound: sound, userInfo: userInfo, attachments: attachments, completion: completion)
            }
            else {
                completion?(self.getNotificationPermissionsError)
            }
        }
        
        func scheduleWithRegion(_ region: CLRegion, repeats: Bool, identifier: String, title: String, subTitle: String = "", body: String = "", badge: NSNumber? = 0, categoryIdentifier: String? = nil, threadIdentifier: String? = nil, launchImageName: String? = nil, sound: UNNotificationSound? = nil, userInfo: [AnyHashable : Any]? = nil, attachments: [UNNotificationAttachment]? = nil, completion: NotificationActionCompletionHandler? = nil) {
            
            
            let notificationContent = getNotificationContentWithTitle(title, subTitle: subTitle, body: body, badge: badge, categoryIdentifier: categoryIdentifier, threadIdentifier: threadIdentifier, launchImageName: launchImageName, sound: sound, userInfo: userInfo)
            let trigger = UNLocationNotificationTrigger.init(region: region, repeats: repeats)
            let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: trigger)
            notificationCenter.add(request) { (error) in
                completion?(error)
            }
        }
    }
    
    //MARK: This method can be used to schedule notifications that fire on specific date and time. It can be used to set repeat interval as well.
    public func scheduleNotificationWithFireDate(_ date: Date, repeatInterval: RepeatInterval = .none, identifier: String, title: String, subTitle: String = "", body: String = "", badge: NSNumber? = 0, categoryIdentifier: String? = nil, threadIdentifier: String? = nil, launchImageName: String? = nil, sound: UNNotificationSound? = nil, userInfo: [AnyHashable : Any]? = nil, attachments: [UNNotificationAttachment]? = nil, completion: NotificationActionCompletionHandler? = nil) {
        
        if scheduledNotificationsCount >= MAXIMUM_ALLOWED_NOTIFICATIONS {
            completion?(getNotificationCountError)
            return
        }
        
        self.checkNotificationSettings { (allowed, _) in
            if allowed {
                scheduleNotificationDate(date, identifier: identifier, title: title, subTitle: subTitle, body: body, badge: badge, categoryIdentifier: categoryIdentifier, threadIdentifier: threadIdentifier, launchImageName: launchImageName, sound: sound, userInfo: userInfo, attachments: attachments, completion: completion)
            }
            else {
                completion?(self.getNotificationPermissionsError)
            }
        }
        
        func scheduleNotificationDate(_ date: Date, repeatInterval: RepeatInterval = .none, identifier: String, title: String, subTitle: String = "", body: String = "", badge: NSNumber? = 0, categoryIdentifier: String? = nil, threadIdentifier: String? = nil, launchImageName: String? = nil, sound: UNNotificationSound? = nil, userInfo: [AnyHashable : Any]? = nil, attachments: [UNNotificationAttachment]? = nil, completion: NotificationActionCompletionHandler? = nil) {
            
            let notificationContent = getNotificationContentWithTitle(title, subTitle: subTitle, body: body, badge: badge, categoryIdentifier: categoryIdentifier, threadIdentifier: threadIdentifier, launchImageName: launchImageName, sound: sound, userInfo: userInfo, attachments: attachments)
            let trigger = triggerForCalendarNotification(forDate: date, repeatInterval: repeatInterval)
            let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: trigger)
            notificationCenter.add(request) { (error) in
                completion?(error)
            }
        }
    }
    
    //MARK: This method can be used to schedule notifications that fire after specific time interval in seconds.
    public func scheduleNotificationWithTimeInterval(_ timeInterval: TimeInterval, repeats: Bool, identifier: String, title: String, subTitle: String = "", body: String = "", badge: NSNumber? = 0, categoryIdentifier: String? = nil, threadIdentifier: String? = nil, launchImageName: String? = nil, sound: UNNotificationSound? = nil, userInfo: [AnyHashable : Any]? = nil, attachments: [UNNotificationAttachment]? = nil, completion: NotificationActionCompletionHandler? = nil) {
        
        if scheduledNotificationsCount >= MAXIMUM_ALLOWED_NOTIFICATIONS {
            completion?(getNotificationCountError)
            return
        }
        
        self.checkNotificationSettings { (allowed, _) in
            if allowed {
                scheduleTimeIntervalNotification(timeInterval, repeats: repeats, identifier: identifier, title: title, subTitle: subTitle, body: body, badge: badge, categoryIdentifier: categoryIdentifier, threadIdentifier: threadIdentifier, launchImageName: launchImageName, sound: sound, userInfo: userInfo, attachments: attachments, completion: completion)
            }
            else {
                completion?(self.getNotificationPermissionsError)
            }
        }
        
        func scheduleTimeIntervalNotification(_ timeInterval: TimeInterval, repeats: Bool, identifier: String, title: String, subTitle: String = "", body: String = "", badge: NSNumber? = 0, categoryIdentifier: String? = nil, threadIdentifier: String? = nil, launchImageName: String? = nil, sound: UNNotificationSound? = nil, userInfo: [AnyHashable : Any]? = nil, attachments: [UNNotificationAttachment]? = nil, completion: NotificationActionCompletionHandler? = nil) {
            
            let notificationContent = getNotificationContentWithTitle(title, subTitle: subTitle, body: body, badge: badge, categoryIdentifier: categoryIdentifier, threadIdentifier: threadIdentifier, launchImageName: launchImageName, sound: sound, userInfo: userInfo, attachments: attachments)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)
            let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: trigger)
            notificationCenter.add(request) { (error) in
                completion?(error)
            }
        }
    }
 }
 
 extension NotificationScheduler: UNUserNotificationCenterDelegate { // UNUserNotificationCenterDelegate    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
 }
 
 public enum RepeatInterval: String {
    case none, hour, day, week, month, year
 }
 
 extension NotificationScheduler {
    private func triggerForCalendarNotification(forDate date: Date, repeatInterval: RepeatInterval) -> UNCalendarNotificationTrigger {
        var dateComponents: DateComponents = DateComponents()
        let shouldRepeat: Bool = repeatInterval != .none
        let calendar: Calendar = Calendar.current
        
        switch repeatInterval {
        case .none, .year:
            dateComponents                 = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        case .month:
            dateComponents                 = calendar.dateComponents([.day, .hour, .minute, .second], from: date)
        case .week:
            dateComponents.weekday         = calendar.component(.weekday, from: date)
            fallthrough
        case .day:
            dateComponents.hour            = calendar.component(.hour, from: date)
            fallthrough
        case .hour:
            dateComponents.minute          = calendar.component(.minute, from: date)
            dateComponents.second          = calendar.component(.second, from: date)
        }
        
        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: shouldRepeat)
    }
    
    
    private func getNotificationContentWithTitle(_ title: String, subTitle: String = "", body: String = "", badge: NSNumber? = 0, categoryIdentifier: String?, threadIdentifier: String?, launchImageName: String?, sound: UNNotificationSound? = nil, userInfo: [AnyHashable : Any]?, attachments: [UNNotificationAttachment]? = nil) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subTitle
        content.body = body
        content.badge = badge
        content.sound = sound
        categoryIdentifier != nil ? content.categoryIdentifier = categoryIdentifier ?? "" : ()
        threadIdentifier != nil ? content.threadIdentifier = threadIdentifier ?? "" : ()
        launchImageName != nil ? content.launchImageName = launchImageName ?? "" : ()
        attachments != nil ? content.attachments = attachments ?? [] : ()
        return content
    }
 }
 
 extension NotificationScheduler { // Errors
    
    private var getNotificationPermissionsError: NSError {
        return createErrorWithText("You have not provided notification permissions to this application.")
    }
    
    private var getNotificationCountError: NSError {
        return createErrorWithText("You had reached maximum allowed notification limit, you cannot schedule more notifications.")
    }
    
    private var getLocationAuthorizationError: NSError {
        return createErrorWithText("You need location access for this application to schedule region monitoring notifications.")
    }
    
    private func createErrorWithText(_ errorText: String) -> NSError {
        let error = NSError(domain: "notificationscheduler.error", code: 501, userInfo: [NSLocalizedDescriptionKey:errorText])
        return error
    }
    
 }
