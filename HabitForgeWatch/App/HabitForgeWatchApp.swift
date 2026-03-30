import SwiftUI
import WatchKit

@main
struct HabitForgeWatchApp: App {
    @StateObject private var watchStore = WatchHabitStore()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(watchStore)
        }

        WKNotificationScene(controller: NotificationController.self, category: "HABIT_ACTION")
    }
}

class NotificationController: WKUserNotificationHostingController<WatchNotificationView> {
    override var body: WatchNotificationView {
        return WatchNotificationView()
    }
}

struct WatchNotificationView: View {
    var body: some View {
        VStack {
            Image(systemName: "bolt.fill")
                .foregroundColor(.purple)
            Text("Habit Alert")
        }
    }
}
