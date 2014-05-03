import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.1

Rectangle {
    color: "#073642"
    anchors.fill: parent

    function textArea() {
        return textEdit
    }

    TextArea {
        property int tabWidth: 4
        readonly property string nbsp: String.fromCharCode(160)
        property string tabstr
        focus: true

        function inSelection() {
            return selectionStart != selectionEnd
        }

        function getLineStart(cp, tx) {
            var linestart = -1;
            while(1) {
                if (cp <= 0) {
                    return 0;
                }
                if (tx.charCodeAt(cp) === 8232 || tx.charCodeAt(cp) === 10) {
                    linestart = cp+1;
                    break;
                }
                cp--;
            }

            return linestart
        }

        function getPosAfterTabs(cp, tx) {
            while(tx.charCodeAt(cp) === 160) {
                cp++;
            }
            return cp;
        }

        Component.onCompleted: {
            forceActiveFocus();

            for(var i=0; i<tabWidth; i++) {
                tabstr+=nbsp;
            }
        }

        Keys.onRightPressed: {
            var cp = cursorPosition+1;
            if (event.modifiers & Qt.ShiftModifier) {
                moveCursorSelection(cp, TextEdit.SelectCharacters);
            } else {
                cursorPosition = cp;
            }
        }

        Keys.onLeftPressed: {
            var cp = cursorPosition-1;
            if (event.modifiers & Qt.ShiftModifier) {
                moveCursorSelection(cp, TextEdit.SelectCharacters);
            } else {
                cursorPosition = cp;
            }
        }

        Keys.onTabPressed: {
            insert(cursorPosition, tabstr);
            event.accepted = true;
        }

        Keys.onPressed: {
            if (event.key === Qt.Key_Backspace && getText(0, length).charCodeAt(cursorPosition-1) === 160) {
                remove(cursorPosition-4, cursorPosition);
                event.accepted = true;
            }

            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                var tx = getText(0, length);
                var prevLs = getLineStart(cursorPosition-1, tx);
                var offset = getPosAfterTabs(prevLs, tx)-prevLs;
                var sps = "";
                for (var i=0; i<offset; ++i) {
                    sps += "&nbsp;";
                }
                insert(cursorPosition, "<br>");
                insert(cursorPosition, sps);
                event.accepted = true;
            }
        }


        onCursorPositionChanged: {
            //Deal with faked tabs created with &nbsp;'s on click and selection
            var cp = cursorPosition;
            var tx = getText(0, length);
            if (tx.charCodeAt(cp) === 160) {
                var linestart = getLineStart(cp, tx);
                if (linestart !== -1) {
                    cp = getPosAfterTabs(cp, tx);
                    if ((cp-linestart) % tabWidth !== 0) {
                        console.exception("nbspaces "+(cp-linestart)+"don't match tabwidth?");
                    }

                    var tabPos = (cursorPosition - linestart) % tabWidth;
                    var tabIdx = ~~((cursorPosition - linestart) / tabWidth);
                    var side = tabPos<2 ? 0 : 1;
                    var newPos = linestart + (tabIdx + side) * tabWidth;
                    if (!inSelection()) {
                        if (tabIdx === 0 && side === 0) {
                            cursorPosition = linestart;
                        } else {
                            cursorPosition = cp;
                        }
                    } else {
                        moveCursorSelection(newPos, TextEdit.SelectCharacters);
                    }
                }
            }
            forceActiveFocus();
        }

        id: textEdit
        frameVisible: false
        width: parent.width
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        font.family: "courier"
        textColor: "#eee8d5"
        baseUrl: "qrc:/"
        selectByMouse: true
        selectByKeyboard: true
        text: '<font color="#859900">///Nothing</font><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#268bd2">func</font> <font color="#eee8d5">Highlight</font><font color="#6c71c4">(</font><font color="#eee8d5">src</font> <font color="#6c71c4">[</font><font color="#6c71c4">]</font><font color="#eee8d5">byte</font><font color="#6c71c4">)</font> <font color="#6c71c4">[</font><font color="#6c71c4">]</font><font color="#eee8d5">byte</font> <font color="#6c71c4">{</font><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#268bd2">var</font> <font color="#eee8d5">b</font> <font color="#eee8d5">bytes</font><font color="#6c71c4">.</font><font color="#eee8d5">Buffer</font><font color="#6c71c4"></font><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#eee8d5">println</font><font color="#6c71c4">(</font><font color="#b58900">2</font><font color="#6c71c4">+</font><font color="#b58900">3</font><font color="#6c71c4">)</font><font color="#6c71c4"></font><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#268bd2">return</font> <font color="#eee8d5">b</font><font color="#6c71c4">.</font><font color="#eee8d5">Bytes</font><font color="#6c71c4">(</font><font color="#6c71c4">)</font><font color="#6c71c4"></font><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#6c71c4">}</font><font color="#6c71c4"></font>'
        textFormat: Qt.RichText
        backgroundVisible: false
    }
}
