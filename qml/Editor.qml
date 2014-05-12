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
        readonly property variant braces: {"(": [Qt.Key_ParenLeft, ")"], "{": [Qt.Key_BraceLeft, "}"]}
        property string braceOpening: ""
        property string htmlTabstr
        property int prevKey: 0
        property string prevText
        property bool undoHandled: false
        property bool needRehighlight: false
        property bool cpSetDontAdjust: false
        signal performUndo()
        signal performRedo()
        signal rehighlight ()
//        signal textGain (string str)
//        signal textLoss (string str)

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

        function getSpaceEnd(tx, pos, delta) {
            var epos = pos;
            while (1) {
                if (epos < 0 || epos >= tx.length) {
                    epos = epos-delta;
                    break;
                }

                var cc = tx.charCodeAt(epos);
                if (cc !== 32 && cc !== 160) {
                    break;
                }
                epos += delta;
            }
            var opos = pos-delta;
            var dist = delta < 0 ? pos-epos : epos-opos;
            if (Math.abs(dist) % tabWidth === 0) {
                return opos+delta*tabWidth;
            }
            return pos;
        }


        function moveOrMoveSel(direction, event) {
            if (direction !== -1 && direction !== 1) {
                return console.exception("WTF direction?");
            }

            var cp = cursorPosition+direction;
            var tx = getText(0, length);
            if (tx.charCodeAt(cp) === 160) {
//                if (direction === -1) {
//                    cp = getLineStart(cp, tx);
//                } else if (direction === 1) {
//                    cp = getPosAfterTabs(cp, tx);
//                }
                cp = getSpaceEnd(tx, cp, direction);
                cpSetDontAdjust = true
            }

            if (event.modifiers & Qt.ShiftModifier) {
                moveCursorSelection(cp, TextEdit.SelectCharacters)
            } else {
                cursorPosition = cp;
            }
        }

        function isEnter(event) {
            return (event.key === Qt.Key_Enter || event.key === Qt.Key_Return);
        }

        function isTextInput(event) {
            return !(event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) &&
                    ((event.key >= Qt.Key_Space && event.key <= Qt.Key_ydiaeresis));
        }

        function isAlphaNumericKey(event) {
            return (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) || (event.key >= Qt.Key_A && event.key <= Qt.Key_Z);
        }

        function doRehighlight() {
            var ocp = cursorPosition;
            rehighlight();
            cursorPosition = ocp;
        }

        function handleTab(event, back) {
            var tx = getText(0, length);
            var newline = String.fromCharCode(8232);
            if (selectedText.indexOf(newline) != -1) { //if it's multiple-line selection than we perform indent
                var selStart = selectionStart;
                var selEnd = selectionEnd;
                var start = getLineStart(selectionStart, tx);
                var end = getPosAfterTabs(getLineStart(selectionEnd-1, tx), tx);
                var lines = getText(start, end).split(newline);
                var eoffset = 0;
                var stoffset = tabWidth;
                for (var ii in lines) {
                    if (back) { //Shift tab
                        var removeEnd = 0;
                        while (removeEnd < lines[ii].length && lines[ii].charCodeAt(removeEnd) === 160 && removeEnd < tabWidth) {
                            removeEnd++;
                        }
                        lines[ii] = lines[ii].substring(removeEnd, lines[ii].length);
                        eoffset -= tabWidth;
                        stoffset = -removeEnd;
                    } else {
                        lines[ii] = tabstr + lines[ii];
                        eoffset += tabWidth;
                    }
                }

                remove(start, end);
                insert(start, lines.join("<br>"));
                doRehighlight()
                select(selStart + stoffset, selEnd + eoffset);
            } else {
                if (inSelection()) {
                    remove(selectionStart, selectionEnd);
                }
                insert(cursorPosition, tabstr);
                doRehighlight()
            }

            event.accepted = true;
        }

        function isControlShortcut(event, key) {
            return event.key === key &&
                    event.modifiers & Qt.ControlModifier && !(event.modifiers & Qt.ShiftModifier) && !(event.modifiers & Qt.AltModifier);
        }

        Component.onCompleted: {
            forceActiveFocus();
            for(var i=0; i<tabWidth; i++) {
                tabstr+=nbsp;
                htmlTabstr+="&nbsp;";
            }
        }

        Keys.onRightPressed: {
            moveOrMoveSel(1, event);
        }

        Keys.onLeftPressed: {
            moveOrMoveSel(-1, event);
        }

        Keys.onPressed: {
            var tx = getText(0, length);
            if (!inSelection()) {
                if (event.key === Qt.Key_Backspace && tx.charCodeAt(cursorPosition-1) === 160) {
                    remove(getSpaceEnd(tx, cursorPosition-1, -1), cursorPosition);
                    event.accepted = true;
                    return;
                }

                if (event.key === Qt.Key_Delete) {
                    if (tx.charCodeAt(cursorPosition) === 8232) {
                        if (cursorPosition <= length-2) {
                            remove(cursorPosition, getPosAfterTabs(getLineStart(cursorPosition+2, tx), tx));
                        }
                        event.accepted = true;
                    } else {
                        if (tx.charCodeAt(cursorPosition+1) === 160) {
                            remove(cursorPosition, getSpaceEnd(tx, cursorPosition, 1));
                            event.accepted = true;
                        }
                    }
                    return;
                }
            }

            if (isEnter(event)) {
                var prevLs = getLineStart(cursorPosition-1, tx);
                var st = getPosAfterTabs(prevLs, tx);
                var offset = st-prevLs;
                var sps = "";
                for (var i=0; i<offset; ++i) {
                    sps += "&nbsp;";
                }
                if (cursorPosition < st) {
                    insert(cursorPosition, sps+"<br>");
                    cursorPosition--;
                } else {
                    if (braceOpening !== "") {
                        //DANGER: inserting triggers cursorPosition change, if not careful this may mess up the braceOpening
                        var closingBrace = braces[braceOpening][1];
                        insert(cursorPosition, "<br>"+sps+htmlTabstr);
                        var cp = cursorPosition;
                        //insert closing brace
                        insert(cursorPosition, "<br>"+sps);
                        insert(cursorPosition, closingBrace);
                        cursorPosition = cp;
                        braceOpening = "";
                    } else {
                        insert(cursorPosition, "<br>"+sps);
                    }
                    doRehighlight()
                }
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Tab) {
                handleTab(event, false);
                return;
            }

            if (event.key === Qt.Key_Backtab) {
                handleTab(event, true);
                return;
            }

            if (isTextInput(event)) {
                if (braceOpening && cursorPosition >= 1 && tx[cursorPosition-1] !== braceOpening) {
                    braceOpening = "";
                }
                //Opening brace handling
                for (var br in braces) {
                    if (event.key === braces[br][0]) {
                        braceOpening = br;
                    }
                }

                //When a word ends, rehighlighting is triggered
                if (!isAlphaNumericKey(event) || !isAlphaNumericKey(prevKey)) {
                    needRehighlight = true;
                }

                prevKey = event.key;
                return;
            }

            if (isControlShortcut(event, Qt.Key_Z)) {
                performUndo()
                event.accepted = true;
                return;
            }

            if (isControlShortcut(event, Qt.Key_Y)) {
                performRedo()
                event.accepted = true;
                return;
            }
        }


        onCursorPositionChanged: {
            if (cpSetDontAdjust) {
                cpSetDontAdjust = false;
                return;
            }

            //Deal with faked tabs created with &nbsp;'s on click and selection
            var cp = cursorPosition;
            var tx = getText(0, length);

            if (tx.charCodeAt(cp) === 160) {
                var linestart = getLineStart(cp, tx);
                if (linestart !== -1) {
                    cp = getPosAfterTabs(linestart, tx);
                    if ((cp-linestart) % tabWidth !== 0) {
                        console.warn("nbspaces "+(cp-linestart)+"don't match tabwidth?");
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
