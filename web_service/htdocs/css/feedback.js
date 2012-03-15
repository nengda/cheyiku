function CreateFeedbackDialog(title, uri) {
    var content = '<textarea id="dts-feedback-message" style="width: 500px; height: 200px; font-family: Verdana; font-size: 9pt; border-style: solid; border-width: 1px; border-color: #cccccc; resize: none"></textarea>';
    var footer = '<div style="width: 100%; text-align: right"><button type="button" onclick="SendFeedback(\'' + title + '\', \'' + uri + '\', document.getElementById(\'dts-feedback-message\').value)">OK</button><button type="button" onclick="CloseDialog(\'dts-feedback-dialog\')">Cancel</button></div>';
    CreateDialog('dts-feedback-dialog', title, content, footer);
}

function SendFeedback(title, uri, message, onComplete) {
    var data = 'type=' + escape(title);
    data += '&uri=' + escape(uri);
    data += '&message=' + escape(message);
    data += '&user_agent=' + escape(navigator.userAgent.toLowerCase());
    CloseDialog('dts-feedback-dialog');
    CreateProgressBar('dts-progress-bar');
    AsyncRequest(
        "POST",
        "/send_feedback.html",
        data,
        "application/x-www-form-urlencoded",
        function(request) {
            CloseDialog('dts-progress-bar');
            if (request.responseText == 'Success') {
                if (onComplete != null) {
                    onComplete();
                }
                else {
                    CreateDialog(
                        'dts-feedback-sent',
                        title,
                        'Your message has been sent successfully.<br/>',
                        '<div style="width: 100%; text-align: right"><button type="button" onclick="CloseDialog(\'dts-feedback-sent\')">Close</button></div>'
                    );
                }
            }
            else {
                alert(request.responseText);
            }
        },
        function(request) {
            CloseDialog('dts-progress-bar');
            alert('Error');
        }
    );
}
