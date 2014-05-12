package main

import "testing"

func TestUndoRedo(t *testing.T) {
	text := []rune("func main() { go initChange() }")
	um := NewUndoMgr()
	text2 := string(text[0:5]) + "hello" + string(text[5:])
	um.Push(command{
		chstr: "hello",
		diff:  5,
		pos:   10,
		kind:  0,
	})
	tx, _ := um.Undo([]rune(text2))
	if tx != string(text) {
		t.Fatalf("Expect `%q`, got `%q`.", string(text), tx)
	}

	tx, _ = um.Redo([]rune(tx))
	if tx != string(text2) {
		t.Fatalf("Expect `%q`, got `%q`.", string(text2), tx)
	}

	//Typing sequence undoing
	um.Push(command{
		chstr: "h",
		diff:  1,
		pos:   6,
		kind:  1,
	})
	um.Push(command{
		chstr: "e",
		diff:  1,
		pos:   7,
		kind:  1,
	})

	text2 = string(text[0:5]) + "he" + string(text[5:])
	tx, _ = um.Undo([]rune(text2))
	if tx != string(text) {
		t.Fatalf("Expect `%q`, got `%q`.", string(text), tx)
	}

	tx, _ = um.Redo([]rune(text))
	if tx != string(text2) {
		t.Fatalf("Expect `%q`, got `%q`.", string(text2), tx)
	}
}
