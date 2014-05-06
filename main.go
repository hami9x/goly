package main

import (
	"fmt"
	"gopkg.in/qml.v0"
	"io/ioutil"
	"os"
)

type Editor struct {
	qml.Object
	tx   qml.Object //the TextArea element from qml
	text []rune
}

func NewEditor(o qml.Object) *Editor {
	return &Editor{
		Object: o,
		tx:     o.Call("textArea").(qml.Object),
	}
}

func (e *Editor) Init() {
	tx := e.tx
	tx.On("rehighlight", func() {
		text := tx.Call("getText", 0, tx.Property("length")).(string)
		e.SetText(QmlHighlight(text))
	})
	tx.On("textChanged", func() {
		e.text = []rune(tx.Call("getText", 0, tx.Property("length")).(string))
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
		e.SetText(QmlHighlight(string(fcb[:])))
	})
}

func (e *Editor) SetText(text string) {
	e.tx.Set("text", text)
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
