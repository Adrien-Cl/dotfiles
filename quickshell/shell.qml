import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import "."

ShellRoot {
    NotificationServer {
        id: notifServer
        keepOnReload: true
        actionsSupported: true
        bodySupported: true

        onNotification: notification => {
            notification.tracked = true
            notification.closed.connect(function() { NotificationState.removeById(notification.id) })
            if (!NotificationState.dnd && notification.appName !== "notify-send")
                NotificationState.add(notification)
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Bar {
            required property ShellScreen modelData
            screen: modelData
            notificationServer: notifServer
        }
    }
}
