import Foundation
import UserNotifications

/// Gentle "your bunny misses you" notifications. Off until a grown-up turns them on behind the grown-up check.
/// Leaving the app schedules two reminders (after 8 hours, then a day later); opening the app cancels them.
/// None arrive at night: a reminder due between 7pm and 9am waits until 9am.
enum Reminders {
    static let onKey = "remindersOn"

    static var isOn: Bool {
        UserDefaults.standard.bool(forKey: onKey)
    }

    /// Shows iOS's "Allow notifications?" question. Returns whether they were allowed.
    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func schedule(bunnyName: String) {
        cancel()
        guard isOn else { return }
        let name = bunnyName.isEmpty ? "Your bunny" : bunnyName
        let messages = [
            ("\(name) misses you!", "Come and say hello in the garden."),
            ("\(name) is wondering where you are", "A tickle and a treat would make the day."),
        ]
        let delays: [TimeInterval] = [8 * 3600, 32 * 3600]
        for (index, delay) in delays.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = messages[index].0
            content.body = messages[index].1
            content.sound = .default
            let when = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                        from: daytime(Date().addingTimeInterval(delay)))
            let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: false)
            UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: "missYou\(index)", content: content, trigger: trigger)
            )
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Moves a time between 7pm and 9am to 9am, so children aren't woken up.
    private static func daytime(_ date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        guard hour >= 19 || hour < 9 else { return date }
        let morning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        return hour >= 19 ? calendar.date(byAdding: .day, value: 1, to: morning) ?? morning : morning
    }
}
