package main

import (
	"fmt"
	"testing"
)

func TestHighlighter(t *testing.T) {
	fmt.Printf("%s\n", QmlHighlight([]byte(`///Nothing
				func Highlight(src []byte) []byte {
				var b bytes.Buffer
				println(2+3)
				return b.Bytes()
			}`)))
}
