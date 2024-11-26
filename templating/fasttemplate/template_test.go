package fasttemplate

import (
	"bytes"
	"errors"
	"testing"
)

func TestExecute(t *testing.T) {
	testExecute(t, "", "")
	testExecute(t, "a", "a")
	testExecute(t, "abc", "abc")
	testExecute(t, "{foo}", "xxxx")
	testExecute(t, "a{foo}", "axxxx")
	testExecute(t, "{foo}a", "xxxxa")
	testExecute(t, "a{foo}bc", "axxxxbc")
	testExecute(t, "{foo}{foo}", "xxxxxxxx")
	testExecute(t, "{foo}bar{foo}", "xxxxbarxxxx")

	// unclosed tag
	testExecute(t, "{unclosed", "{unclosed")
	testExecute(t, "{{unclosed", "{{unclosed")
	testExecute(t, "{un{closed", "{un{closed")

	// test unknown tag
	testExecute(t, "{unknown}", "{unknown}")
	testExecute(t, "{foo}q{unexpected}{missing}bar{foo}", "xxxxq{unexpected}{missing}barxxxx")
	testExecute(t, "{foo}q{ unexpected }{ missing }bar{foo}", "xxxxq{ unexpected }{ missing }barxxxx")
}

func testExecute(t *testing.T, template, expectedOutput string) {
	var bb bytes.Buffer
	params := TemplateParams{}
	params.AddString("foo", "xxxx")

	if !params.Contains("foo") {
		t.Fatalf("unexpected missing key: foo")
	}

	if params.Contains("bar") {
		t.Fatalf("unexpected key: bar")
	}

	n, err := params.Execute(template, "{", "}", &bb)
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if n != len(expectedOutput) {
		t.Fatalf("unexpected number of bytes written: %d. Expected %d", n, len(expectedOutput))
	}
	output := bb.String()
	if output != expectedOutput {
		t.Fatalf("unexpected output for template=%q: %q. Expected %q", template, output, expectedOutput)
	}

	// []byte
	bb.Reset()
	params = TemplateParams{}
	params.AddBytes("foo", []byte("xxxx"))
	n, err = params.Execute(template, "{", "}", &bb)
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if n != len(expectedOutput) {
		t.Fatalf("unexpected number of bytes written: %d. Expected %d", n, len(expectedOutput))
	}
	output = bb.String()
	if output != expectedOutput {
		t.Fatalf("unexpected output for bytes[] value template=%q: %q. Expected %q", template, output, expectedOutput)
	}

	// TagFunc
	bb.Reset()
	params = TemplateParams{}
	params.AddFunc("foo", func(w Writer) (int, error) {
		return w.WriteString("xxxx")
	})
	n, err = params.Execute(template, "{", "}", &bb)
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if n != len(expectedOutput) {
		t.Fatalf("unexpected number of bytes written: %d. Expected %d", n, len(expectedOutput))
	}
	output = bb.String()
	if output != expectedOutput {
		t.Fatalf("unexpected output for TagFunc value template=%q: %q. Expected %q", template, output, expectedOutput)
	}

}

func TestExecuteString(t *testing.T) {
	testExecuteString(t, "", "")
	testExecuteString(t, "a", "a")
	testExecuteString(t, "abc", "abc")
	testExecuteString(t, "{foo}", "xxxx")
	testExecuteString(t, "a{foo}", "axxxx")
	testExecuteString(t, "{foo}a", "xxxxa")
	testExecuteString(t, "a{foo}bc", "axxxxbc")
	testExecuteString(t, "{foo}{foo}", "xxxxxxxx")
	testExecuteString(t, "{foo}bar{foo}", "xxxxbarxxxx")

	// unclosed tag
	testExecuteString(t, "{unclosed", "{unclosed")
	testExecuteString(t, "{{unclosed", "{{unclosed")
	testExecuteString(t, "{un{closed", "{un{closed")

	// test unknown tag
	testExecuteString(t, "{unknown}", "{unknown}")
	testExecuteString(t, "{foo}q{unexpected}{missing}bar{foo}", "xxxxq{unexpected}{missing}barxxxx")
	testExecuteString(t, "{foo}q{ unexpected }{ missing }bar{foo}", "xxxxq{ unexpected }{ missing }barxxxx")
}

func testExecuteString(t *testing.T, template, expectedOutput string) {
	m := TemplateParams{}
	m.AddString("foo", "xxxx")
	output := m.ExecuteString(template, "{", "}")
	if output != expectedOutput {
		t.Fatalf("unexpected output for template=%q: %q. Expected %q", template, output, expectedOutput)
	}
}

var errTest = errors.New("test error")

type errWriter struct{}

func (errWriter) Write(p []byte) (int, error) {
	return 0, errTest
}
func (errWriter) WriteString(s string) (int, error) {
	return 0, errTest
}
func TestWriteError(t *testing.T) {
	params := TemplateParams{}
	params.AddString("foo", "xxxx")
	_, err := params.Execute("a{foo}b", "{", "}", &errWriter{})
	if err != errTest {
		t.Fatalf("unexpected error: %s. Expected %s", err, errTest)
	}
}
