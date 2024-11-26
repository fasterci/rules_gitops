/*
Copyright 2020 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/
package main

import (
	"flag"
	"io"
	"log"
	"os"
	"strings"

	"github.com/fasterci/rules_gitops/templating/fasttemplate"
)

type arrayFlags []string

func (i *arrayFlags) String() string {
	return ""
}

func (i *arrayFlags) Set(value string) error {
	*i = append(*i, value)
	return nil
}

var (
	stampInfoFile     arrayFlags
	failIfStamped     bool
	output, template  string
	variable, imports arrayFlags
	executable        bool
	startTag, endTag  string
)

func init() {
	flag.Var(&stampInfoFile, "stamp_info_file", "Paths to info_file and version_file files for stamping. Content of stamp_info_file files will be used to substitute variable values so --variable VAR={BUILD_USER}/value will result in {{VAR}} being expanded to builduser/value")
	flag.BoolVar(&failIfStamped, "fail_if_stamped", false, "Whether to fail if the template contains a stamp")
	flag.Var(&variable, "variable", "A variable to expand in the template, in the format NAME=VALUE")
	flag.Var(&imports, "imports", "A file to import as another template, in the format NAME=filename")
	flag.StringVar(&output, "output", "", "The output file")
	flag.StringVar(&template, "template", "", "The input file, mandatory")
	flag.BoolVar(&executable, "executable", false, "Whether to adds the executable bit to the output")
	flag.StringVar(&startTag, "start_tag", "{{", "Start tag for template placeholders")
	flag.StringVar(&endTag, "end_tag", "}}", "End tag for template placeholders")
}

func workspaceStatusDict(filenames []string) fasttemplate.TemplateParams {
	d := fasttemplate.TemplateParams{}
	for _, f := range filenames {
		content, err := os.ReadFile(f)
		if err != nil {
			log.Fatalf("Unable to read %s: %v", f, err)
		}
		for _, l := range strings.Split(string(content), "\n") {
			if key, val, ok := strings.Cut(l, " "); ok {
				d.AddFunc(key, func(w fasttemplate.Writer) (int, error) {
					if failIfStamped {
						log.Fatalf("Template contains a stamp: %s", key)
					}
					return w.WriteString(val)
				})
			}
		}
	}
	return d
}

func main() {
	var err error
	flag.Parse()
	stamps := workspaceStatusDict(stampInfoFile)
	vars := fasttemplate.TemplateParams{}
	for _, v := range variable {
		k, val, ok := strings.Cut(v, "=")
		if !ok {
			log.Fatalf("variable must be VAR=value, got %s", v)
		}
		if vars.Contains(k) {
			log.Fatalf("Duplicate variable name %s", k)
		}
		val = stamps.ExecuteString(val, "{", "}")
		vars.AddString(k, val)
		vars.AddString("variables."+k, val)
	}

	for _, v := range imports {
		k, fname, ok := strings.Cut(v, "=")
		if !ok {
			log.Fatalf("imports must be VAR=filename, got %s", v)
		}
		if vars.Contains(k) {
			log.Fatalf("Duplicate variable name %s in imports", k)
		}
		imp, err := os.ReadFile(fname)
		if err != nil {
			log.Fatalf("Unable to parse file %s: %v", fname, err)
		}
		val := vars.ExecuteString(string(imp), startTag, endTag)
		val = stamps.ExecuteString(val, "{", "}")
		vars.AddString(k, val)
		vars.AddString("imports."+k, val)
	}

	var tpl []byte
	if template != "" {
		tpl, err = os.ReadFile(template)
		if err != nil {
			log.Fatalf("Unable to read template %s: %v", template, err)
		}
	} else {
		tpl, err = io.ReadAll(os.Stdin)
		if err != nil {
			log.Fatalf("Unable to read template from stdin: %v", err)
		}
	}
	outf := os.Stdout
	if output != "" {
		var perm os.FileMode = 0666
		if executable {
			perm = 0777
		}
		outf, err = os.OpenFile(output, os.O_RDWR|os.O_CREATE|os.O_TRUNC, perm)
		if err != nil {
			log.Fatalf("Unable to create output file %s: %v", output, err)
		}
		defer outf.Close()
	}
	_, err = vars.Execute(string(tpl), startTag, endTag, outf)
	if err != nil {
		log.Fatalf("Unable to execute template %s: %v", template, err)
	}
}
