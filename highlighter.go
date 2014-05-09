//This code is originally copied from litebrite
/*Copyright (c) 2012, Daniel Connelly. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

Neither the name of Daniel Connelly nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*/

package main

import (
	"bytes"
	"fmt"
	"go/scanner"
	"go/token"
	"strings"
)

type tokenType int32

const (
	Identifier tokenType = iota
	Keyword
	Literal
	Operator
	Comment
	Illegal
)

// Code color theme hard-coded
var (
	Colors = map[tokenType]string{
		Identifier: "#eee8d5",
		Literal:    "#b58900",
		Operator:   "#6c71c4",
		Comment:    "#859900",
		Illegal:    "#dc322f",
		Keyword:    "#268bd2",
	}
)

// ## Source tokenizing

// sep represents a split in source code due to a token occurrence.
type sep struct {
	pos int
	tok token.Token
}

// tokenize scans src and emits a sep on every token occurrence.
func tokenize(src []byte, tc chan *sep) {
	var s scanner.Scanner
	fset := token.NewFileSet() // boilerplate stuff for scanner...
	file := fset.AddFile("", fset.Base(), len(src))
	s.Init(file, src, nil, 1)
	for {
		filePos, tok, _ := s.Scan()
		tc <- &sep{int(filePos) - file.Base(), tok}
		if tok == token.EOF {
			close(tc)
			break
		}
	}
}

// tokens returns a channel that emits seps from tokenizing src.
func tokens(src []byte) <-chan *sep {
	tc := make(chan *sep)
	go tokenize(src, tc)
	return tc
}

// trim splits a source chunk into three pieces: the leading whitespace, the source code,
// and the trailing whitespace.
func trim(chunk string) (string, string, string) {
	code := strings.TrimSpace(chunk)
	wsl := chunk[:strings.Index(chunk, code)]
	wsr := chunk[len(wsl)+len(code):]
	return wsl, code, wsr
}

func getColor(tok token.Token) string {
	switch {
	case tok.IsKeyword():
		return Colors[Keyword]
	case tok.IsLiteral():
		if tok == token.IDENT {
			return Colors[Identifier]
		} else {
			return Colors[Literal]
		}
	case tok.IsOperator():
		return Colors[Operator]
	case tok == token.COMMENT:
		return Colors[Comment]
	case tok == token.ILLEGAL:
		return Colors[Illegal]
	default:
		panic(fmt.Sprintf("unknown token type: %v", tok))
	}
	return ""
}

func qmlize(str string) string {
	ostr := ""
	var prevCh rune = 0
	for _, c := range str {
		o := string(c)
		switch c {
		case '\n', 8232:
			o = "<br>"
		case '\t':
			o = "&nbsp;&nbsp;&nbsp;&nbsp;"
		case ' ':
			if prevCh == c {
				o = "&nbsp;"
			}
		}
		ostr += o
		prevCh = c
	}
	return ostr
}

// Highlight returns the QML HTML representation for the source
func QmlHighlight(osrc string) string {
	var b bytes.Buffer
	src := ""
	for _, ch := range osrc {
		switch ch {
		case 8232:
			src += "\n"
		default:
			src += string(ch)
		}
	}
	tc := tokens([]byte(src))
	prev := <-tc
	for cur := <-tc; cur != nil; prev, cur = cur, <-tc {
		wsl, code, wsr := trim(string(src)[prev.pos:cur.pos])
		b.WriteString(qmlize(wsl))
		b.WriteString(fmt.Sprintf(`<font color="%v">%v</font>`, getColor(prev.tok), code))
		b.WriteString(qmlize(wsr))
	}
	return string(b.Bytes())
}
