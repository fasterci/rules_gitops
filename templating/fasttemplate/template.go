// Package fasttemplate implements simple and fast template library.
//
// Fasttemplate is faster than text/template, strings.Replace
// and strings.Replacer.
//
// Fasttemplate ideally fits for fast and simple placeholders' substitutions.
package fasttemplate

import (
	"fmt"
	"io"
	"strings"
)

type Writer interface {
	io.Writer
	io.StringWriter
}

// executeFunc calls f on each template tag (placeholder) occurrence.
//
// Returns the number of bytes written to w.
func executeFunc(template, startTag, endTag string, w Writer, f TagFunc) (int, error) {
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
		tag := template[:n]
		ni, err = f(w, tag)
		nn += ni
		if err != nil {
			if _, ok := err.(ErrMissingTag); ok {
				ni, err = w.WriteString(startTag + tag + endTag)
				nn += ni
				if err != nil {
					return nn, err
				}
			} else {
				return nn, err
			}
		}
		template = template[n+len(endTag):]
	}
	ni, err = w.WriteString(template)
	nn += ni

	return nn, err
}

// Execute substitutes template tags (placeholders) with the corresponding
// values from the map m and writes the result to the given writer w.
//
// Substitution map m may contain values with the following types:
//   - []byte - the fastest value type
//   - string - convenient value type
//   - TagFunc - flexible value type
//
// Returns the number of bytes written to w.
func Execute(template, startTag, endTag string, w Writer, m map[string]interface{}) (int, error) {
	return executeFunc(template, startTag, endTag, w, func(w Writer, tag string) (int, error) { return stdTagFunc(w, tag, m) })
}

// executeFuncString calls f on each template tag (placeholder) occurrence
// and substitutes it with the data written to TagFunc's w.
//
// Returns the resulting string.
func executeFuncString(template, startTag, endTag string, f TagFunc) string {
	if !strings.Contains(template, startTag) {
		return template
	}

	bb := &strings.Builder{}
	if _, err := executeFunc(template, startTag, endTag, bb, f); err != nil {
		panic(fmt.Sprintf("unexpected error: %s", err))
	}
	return bb.String()
}

// ExecuteString substitutes template tags (placeholders) with the corresponding
// values from the map m and returns the result.
//
// Substitution map m may contain values with the following types:
//   - []byte - the fastest value type
//   - string - convenient value type
//   - TagFunc - flexible value type
func ExecuteString(template, startTag, endTag string, m map[string]interface{}) string {
	return executeFuncString(template, startTag, endTag, func(w Writer, tag string) (int, error) { return stdTagFunc(w, tag, m) })
}

// TagFunc can be used as a substitution value in the map passed to Execute*.
// Execute* functions pass tag (placeholder) name in 'tag' argument.
//
// TagFunc must be safe to call from concurrently running goroutines.
//
// TagFunc must write contents to w and return the number of bytes written.
type TagFunc func(w Writer, tag string) (int, error)

type ErrMissingTag string

func (e ErrMissingTag) String() string {
	return e.Error()
}

func (e ErrMissingTag) Error() string {
	return "tag " + string(e) + " not found"
}

func stdTagFunc(w Writer, tag string, m map[string]interface{}) (int, error) {
	tag = strings.TrimSpace(tag)
	v, exists := m[tag]
	if !exists {
		return 0, ErrMissingTag(tag)
	}
	if v == nil {
		return 0, nil
	}
	switch value := v.(type) {
	case []byte:
		return w.Write(value)
	case string:
		return w.WriteString(value)
	case TagFunc:
		return value(w, tag)
	case func(w Writer, tag string) (int, error):
		return value(w, tag)
	// this is the old signature of the TagFunc. It is kept for compatibility.
	case func(w io.Writer, tag string) (int, error):
		return value(w, tag)
	case fmt.Stringer:
		return w.WriteString(value.String())
	default:
		panic(fmt.Sprintf("tag=%q contains unexpected value type=%#v. Expected []byte, string, TagFunc or fmt.Stringer", tag, v))
	}
}
