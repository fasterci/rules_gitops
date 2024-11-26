package fasttemplate

import (
	"fmt"
	"net/url"
)

func ExampleTemplate() {
	template := "http://{{host}}/?foo={{bar}}{{bar}}&q={{query}}&baz={{baz}}"

	// Substitution parameters.
	// Since "baz" tag is missing in the parameters, it will be left unchanged.
	m := TemplateParams{}
	m.AddString("host", "google.com")   // string
	m.AddBytes("bar", []byte("foobar")) // byte slice
	m.AddFunc("query", func(w Writer) (int, error) {
		return w.WriteString(url.QueryEscape("query=world"))
	})

	s := m.ExecuteString(template, "{{", "}}")
	fmt.Printf("%s", s)

	// Output:
	// http://google.com/?foo=foobarfoobar&q=query%3Dworld&baz={{baz}}
}

func ExampleTemplateWithSpaces() {
	template := "http://{{ host }}/?foo={{ bar }}{{ bar }}&q={{ query }}&baz={{ baz }}"

	// Substitution parameters.
	// Since "baz" tag is missing in the parameters, it will be left unchanged.
	m := TemplateParams{}
	m.AddString("host", "google.com")   // string
	m.AddBytes("bar", []byte("foobar")) // byte slice
	m.AddFunc("query", func(w Writer) (int, error) {
		return w.WriteString(url.QueryEscape("query=world"))
	})

	s := m.ExecuteString(template, "{{", "}}")
	fmt.Printf("%s", s)

	// Output:
	// http://google.com/?foo=foobarfoobar&q=query%3Dworld&baz={{ baz }}
}

func ExampleTagFunc() {
	template := "foo[baz]bar"

	// Substitution parameters.
	// Since "baz" tag is missing in the parameters, it will be left unchanged.
	m := TemplateParams{}
	bazSlice := [][]byte{[]byte("123"), []byte("456"), []byte("789")}
	m.AddFunc("baz", func(w Writer) (int, error) {
		var nn int
		for _, x := range bazSlice {
			n, err := w.Write(x)
			if err != nil {
				return nn, err
			}
			nn += n
		}
		return nn, nil
	})

	s := m.ExecuteString(template, "[", "]")

	fmt.Printf("%s", s)

	// Output:
	// foo123456789bar
}
