pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    property ListModel toasts: ListModel {}

    function add(notif) {
        toasts.append({
            "notifId":       notif.id,
            "notifAppName":  notif.appName   || "",
            "notifAppIcon":  notif.appIcon   || "",
            "notifImage":    notif.image     || "",
            "notifSummary":  notif.summary   || "",
            "notifBody":     notif.body      || "",
            "notifUrgency":  notif.urgency * 1 || 1,
            "notifObject":   notif,
            "notifTime":     new Date().getTime(),
            "notifCategory": _categorize(notif)
        })
    }

    function removeById(notifId) {
        for (var i = 0; i < toasts.count; i++) {
            if (toasts.get(i).notifId === notifId) {
                toasts.remove(i)
                return
            }
        }
    }

    function _categorize(notif) {
        var name = (notif.appName || "").toLowerCase()
        if (name.indexOf("kdeconnect") >= 0) return "phone"
        if (["spotify","rhythmbox","vlc","clementine","elisa","audacious","mpd"].indexOf(name) >= 0) return "media"
        if ((notif.urgency * 1 || 1) >= 2) return "critical"
        return "default"
    }

    function relativeTime(ts) {
        var d = (new Date().getTime() - ts) / 1000
        if (d < 60)    return "maintenant"
        if (d < 3600)  return Math.floor(d / 60) + " min"
        if (d < 86400) return Math.floor(d / 3600) + " h"
        return Math.floor(d / 86400) + " j"
    }
}
