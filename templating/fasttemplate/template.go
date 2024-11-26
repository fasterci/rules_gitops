// Package fasttemplate implements simple and fast template library.
//
// Fasttemplate is faster than text/template, strings.Replace
// and strings.Replacer.
//
// Fasttemplate ideally fits for fast and simple placeholders' substitutions.
package fasttemplate

import (
	"io"
	"strings"
)

type Writer interface {
	io.Writer
	io.StringWriter
}

// TagFunc can be used as a substitution value in the map passed to Execute*.
// Execute* functions pass tag (placeholder) name in 'tag' argument.
//
// TagFunc must be safe to call from concurrently running goroutines.
//
// TagFunc must write contents to w and return the number of bytes written.
type TagFunc func(w Writer) (int, error)

type TemplateParams map[string]TagFunc

func (t TemplateParams) AddString(key string, value string) {
	t[key] = func(w Writer) (int, error) {
		return w.WriteString(value)
	}
}

func (t TemplateParams) AddBytes(key string, value []byte) {
	t[key] = func(w Writer) (int, error) {
		return w.Write(value)
	}
}

func (t TemplateParams) AddFunc(key string, value TagFunc) {
	t[key] = value
}

func (t TemplateParams) Contains(key string) bool {
	_, ok := t[key]
	return ok
}

// Execute substitutes template tags (placeholders) with the corresponding
// values from the map m and writes the result to the given writer w.
//
// returns the number of bytes written to w and the first error encountered.
func (t TemplateParams) Execute(template, startTag, endTag string, w Writer) (int, error) {
	var nn int
	var ni int
	var err error
	for {
		n := strings.Index(template, startTag)
		if n < 0 {
			break
		}
		ni, err = w.WriteString(template[:n])
		nn += ni
		if err != nil {
			return nn, err
		}

		template = template[n+len(startTag):]
		n = strings.Index(template, endTag)
		if n < 0 {
			// cannot find end tag - just write it to the output.
			ni, err = w.WriteString(startTag)
			nn += ni
			if err != nil {
				return nn, err
			}
			break
		}
		fulltag := template[:n]
		tag := strings.TrimSpace(fulltag)
		if f, exists := t[tag]; exists {
			ni, err = f(w)
		} else {
			ni, err = w.WriteString(startTag + fulltag + endTag)
		}
		nn += ni
		if err != nil {
			return nn, err
		}
		template = template[n+len(endTag):]
	}
	ni, err = w.WriteString(template)
	nn += ni

	return nn, err
}

// ExecuteString substitutes template tags (placeholders) with the corresponding
// values from the map m and returns the result.
func (t TemplateParams) ExecuteString(template, startTag, endTag string) string {
	bb := &strings.Builder{}
	_, _ = t.Execute(template, startTag, endTag, bb)
	return bb.String()
}
