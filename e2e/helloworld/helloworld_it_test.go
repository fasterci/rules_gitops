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
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"testing"

	"github.com/fasterci/rules_gitops/testing/it_sidecar/client"
)

var setup client.K8STestSetup

func TestMain(m *testing.M) {
	setup = client.K8STestSetup{
		WaitForPods: []string{"helloworld"},
		PortForwardServices: map[string]int{
			"helloworld": 8080,
		},
	}
	setup.TestMain(m)
}

func TestSimpleServer(t *testing.T) {
	appServerPort := setup.GetServiceLocalPort("helloworld")
	response, err := http.Get(fmt.Sprintf("http://localhost:%d", appServerPort))
	if err != nil {
		t.FailNow()
	}
	if response.StatusCode != 200 {
		t.Errorf("Expected status code 200, got %d", response.StatusCode)
	}
	body, _ := ioutil.ReadAll(response.Body)
	if !strings.Contains(string(body), "Hello World") {
		t.Error("Unexpected content returned:", string(body))
	}
}
