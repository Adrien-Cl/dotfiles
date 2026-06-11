pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    property ListModel toasts: ListModel {}
    property bool dnd: false
    property int  _tick: 0
    property var  _timestamps: ({})

    Timer {
        interval: 30000
        repeat:   true
        running:  true
        onTriggered: root._tick++
    }

    function add(notif) {
        if (toasts.count >= 4) toasts.remove(0)
        var ts = new Date().getTime()
        var map = root._timestamps
        map[notif.id] = ts
        root._timestamps = map
        toasts.append({
            "notifId":       notif.id,
            "notifAppName":  notif.appName   || "",
            "notifAppIcon":  notif.appIcon   || "",
            "notifImage":    notif.image     || "",
            "notifSummary":  notif.summary   || "",
            "notifBody":     notif.body      || "",
            "notifUrgency":  notif.urgency * 1 || 1,
            "notifObject":   notif,
            "notifTime":     ts,
            "notifCategory": _categorize(notif)
        })
    }

    function removeById(notifId) {
        for (var i = 0; i < toasts.count; i++) {
            if (toasts.get(i).notifId === notifId) {
                toasts.remove(i)
                break
            }
        }
        var map = root._timestamps
        delete map[notifId]
        root._timestamps = map
    }

    function getRelativeTime(id) {
        var dummy = root._tick
        var ts = root._timestamps[id] || 0
        return relativeTime(ts)
    }

    function _categorize(notif) {
        var name = (notif.appName || "").toLowerCase()
        if (name.indexOf("kdeconnect") >= 0) return "phone"
        if (["spotify","rhythmbox","vlc","clementine","elisa","audacious","mpd"].indexOf(name) >= 0) return "media"
        if ((notif.urgency * 1 || 1) >= 2) return "critical"
        return "default"
    }

    function relativeTime(ts) {
        if (!ts) return ""
        var d = (new Date().getTime() - ts) / 1000
        if (d < 60)    return "maintenant"
        if (d < 3600)  return Math.floor(d / 60) + " min"
        if (d < 86400) return Math.floor(d / 3600) + " h"
        return Math.floor(d / 86400) + " j"
    }
}
