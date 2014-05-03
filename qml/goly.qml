/****************************************************************************
**
** Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/legal
**
** This file is part of the Qt Quick Controls module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of Digia Plc and its Subsidiary(-ies) nor the names
**     of its contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/
import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.1

ApplicationWindow {
    width: 640
    height: 480
    minimumWidth: 400
    minimumHeight: 300

    title: "Goly IDE"

    MessageDialog {
        id: aboutBox
        title: "About Text"
        text: "This is a basic text editor \nwritten with Qt Quick Controls"
        icon: StandardIcon.Information
    }

    Action {
        id: cutAction
        text: "Cut"
        shortcut: "ctrl+x"
        iconSource: "images/editcut.png"
        iconName: "edit-cut"
        onTriggered: textArea.cut()
    }

    Action {
        id: copyAction
        text: "Copy"
        shortcut: "Ctrl+C"
        iconSource: "images/editcopy.png"
        iconName: "edit-copy"
        onTriggered: textArea.copy()
    }

    Action {
        id: pasteAction
        text: "Paste"
        shortcut: "ctrl+v"
        iconSource: "qrc:images/editpaste.png"
        iconName: "edit-paste"
        onTriggered: textArea.paste()
    }

    FileDialog {
        id: fileDialog
        nameFilters: ["Go source code (*.go)"]
        onAccepted: editor.file = fileUrl
    }

    Action {
        id: fileOpenAction
        iconSource: "images/fileopen.png"
        iconName: "document-open"
        text: "Open"
        shortcut: "ctrl+O"
        onTriggered: fileDialog.open()
    }

    menuBar: MenuBar {
        Menu {
            title: "&File"
            MenuItem {
                action: fileOpenAction
            }
            MenuItem {
                text: "Quit"
                onTriggered: Qt.quit()
            }
        }
        Menu {
            title: "&Edit"
            MenuItem {
                action: copyAction
            }
            MenuItem {
                action: cutAction
            }
            MenuItem {
                action: pasteAction
            }
        }
        Menu {
            title: "&Help"
            MenuItem {
                text: "About..."
                onTriggered: aboutBox.open()
            }
        }
    }

    Editor {
        id: editor
        objectName: "editor"

        property string file
    }
}
