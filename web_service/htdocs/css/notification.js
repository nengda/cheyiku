var _notifications = null;
var _notificationIndex = -1;

function ShowNotifications(notifications) {
    _notifications = notifications;
    ShowNextNotification();
}

function ShowNextNotification() {
    if (_notificationIndex != -1) {
        if (document.getElementById('dts-notification-dontshowagain').checked) {
            CreateCookie('dts-notifications-read' + _notifications[_notificationIndex].id, "true", 1461);
        }
        CloseDialog('dts-notification-' + _notifications[_notificationIndex].id);
    }

    _notificationIndex++;
    while (_notificationIndex < _notifications.length && ReadCookie('dts-notifications-read' + _notifications[_notificationIndex].id)) {
        _notificationIndex++;
    }

    if (_notificationIndex < _notifications.length) {
        CreateDialog(
            'dts-notification-' + _notifications[_notificationIndex].id,
             _notifications[_notificationIndex].title,
             _notifications[_notificationIndex].message + '<br/><br/>',
             '<table width="100%" border="0" cellspacing="0" cellpadding="0"><tr><td width="18"><input type="CHECKBOX" id="dts-notification-dontshowagain"></td><td style="color:#4c4c4c">Do not show this message again</td><td align="right"><span class="button-group"><button type="button" class="default" onclick="ShowNextNotification()">Close</button></span></td></tr></table>',
             500
        );
    }
}
