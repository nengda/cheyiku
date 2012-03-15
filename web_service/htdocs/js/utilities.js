function GetTitleWidth() {
    var titleDiv = document.getElementById('dts-title-text');
    return titleDiv.offsetLeft * 2 + titleDiv.offsetWidth;
}

function GetTitleHeight() {
    var titleDiv = document.getElementById('dts-title-text');
    return titleDiv.offsetTop * 2 + titleDiv.offsetHeight;
}
