package main

import (
	"fmt"
	"io/ioutil"
	"os"

	qml "gopkg.in/qml.v0"
)

const (
	TypingAction = 1
)

type command struct {
	chstr string
	pos   int
	diff  int
	kind  int
}

func (c command) do(text []rune, diff int, pos int) string {
	//fmt.Printf("%q %v %v\n", c.chstr, pos, c.diff)
	if diff < 0 {
		return string(text[0:pos+diff]) + string(text[pos:])
	}
	return string(text[0:pos]) + c.chstr + string(text[pos:])
}

func (c command) Redo(text []rune) string {
	return c.do(text, c.diff, c.OldPos())
}

func (c command) Undo(text []rune) string {
	return c.do(text, -c.diff, c.pos)
}

func (c command) OldPos() int {
	return c.pos - c.diff
}

type UndoMgr struct {
	undostack []command
	redostack []command
}

func NewUndoMgr() *UndoMgr {
	return &UndoMgr{make([]command, 0), make([]command, 0)}
}

func (um *UndoMgr) Push(cmd command) {
	um.undostack = append(um.undostack, cmd)
	um.redostack = um.redostack[0:0]
}

func (um *UndoMgr) do(text []rune, from *[]command, to *[]command, undo bool, pos int) (newText string, newPos int) {
	if len(*from) < 1 {
		return string(text), pos
	}
	cmd := (*from)[len(*from)-1]
	dpos := cmd.pos //the pos to verify if it's in the typing sequence
	if !undo {
		dpos = cmd.OldPos()
	}
	if pos != -1 && (cmd.kind != TypingAction || pos != dpos) {
		return string(text), pos
	}

	*from = (*from)[0 : len(*from)-1] //pop from from
	*to = append(*to, cmd)            //push to to

	if undo {
		newText, newPos = cmd.Undo(text), cmd.OldPos()
	} else {
		newText, newPos = cmd.Redo(text), cmd.pos
	}

	if cmd.kind == TypingAction {
		newText, newPos = um.do([]rune(newText), from, to, undo, newPos)
		return
	}

	return
}

func (um *UndoMgr) Undo(text []rune) (string, int) {
	return um.do(text, &um.undostack, &um.redostack, true, -1)
}

func (um *UndoMgr) Redo(text []rune) (string, int) {
	return um.do(text, &um.redostack, &um.undostack, false, -1)
}

type Editor struct {
	qml.Object
	tx            qml.Object //the TextArea element from qml
	text          []rune
	onRehighlight bool
	um            *UndoMgr
}

func NewEditor(o qml.Object) *Editor {
	e := &Editor{
		Object: o,
		tx:     o.Call("textArea").(qml.Object),
		um:     NewUndoMgr(),
	}
	return e
}

func (e *Editor) SetText(text string) {
	text = QmlHighlight(text)
	e.onRehighlight = true
	curPos := e.tx.Property("cursorPosition").(int)
	e.tx.Set("text", text)
	e.tx.Set("cursorPosition", curPos)
	e.text = []rune(e.Text())
}

func (e *Editor) Text() string {
	return e.tx.Call("getText", 0, e.tx.Property("length")).(string)
}

func (e *Editor) rehighlight() {
	if e.onRehighlight {
		return
	}
	//fmt.Printf("%q\n", e.Text())
	e.SetText(e.Text())
}

func (e *Editor) Init() {
	tx := e.tx
	e.text = []rune(e.Text())
	tx.On("rehighlight", e.rehighlight)
	tx.On("textChanged", func() {
		if e.onRehighlight {
			e.onRehighlight = false
			return
		}
		prevText := e.text
		text := []rune(e.Text())
		//println(";" + prevText + ";")
		//println("." + text + ".")
		lendiff := len(text) - len(prevText)
		curPos := tx.Property("cursorPosition").(int)
		if lendiff == 0 {
			return
		}
		//fmt.Printf("%q\n", ";"+string(text[0:curPos-lendiff])+";")
		//fmt.Printf("%q\n", "."+string(prevText[0:curPos-lendiff])+".")
		spos := curPos
		if lendiff > 0 {
			spos = curPos - lendiff
		}
		//fmt.Printf("n: %v, %v -> %v, %v\n", lendiff, curPos, curPos-lendiff+1, spos)
		if string(text[0:spos]) == string(prevText[0:spos]) {
			change := make([]rune, 0)
			if lendiff < 0 {
				change = prevText[curPos : curPos-lendiff]
			} else {
				change = text[curPos-lendiff : curPos]
			}
			kind := 0
			if lendiff == 1 {
				kind = TypingAction
			}
			//fmt.Printf("%v\n", int(text[curPos-lendiff]))
			e.um.Push(command{
				chstr: string(change),
				diff:  lendiff,
				pos:   curPos,
				kind:  kind,
			})
		}
		e.text = text
		if e.tx.Property("needRehighlight").(bool) {
			e.tx.Set("needRehighlight", false)
			e.rehighlight()
		}
	})

	tx.On("performUndo", func() {
		text, pos := e.um.Undo(e.text)
		e.SetText(text)
		e.tx.Set("cursorPosition", pos)

	})

	tx.On("performRedo", func() {
		text, pos := e.um.Redo(e.text)
		e.SetText(text)
		e.tx.Set("cursorPosition", pos)
	})

	e.On("fileChanged", func() {
		filePath := e.String("file")
		if filePath[:7] == "file://" {
			filePath = filePath[6:]
		}
		fcb, err := ioutil.ReadFile(filePath)
		if err != nil {
			panic(err.Error())
		}
		e.SetText(string(fcb[:]))
	})
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	qml.Init(nil)
	engine := qml.NewEngine()

	component, err := engine.LoadFile("qml/goly.qml")
	if err != nil {
		return err
	}

	win := component.CreateWindow(nil)
	win.Show()
	editor := NewEditor(win.ObjectByName("editor"))
	editor.Init()
	win.Wait()

	return nil
}
