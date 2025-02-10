package test

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// JsonnetTest represents a single test case
type JsonnetTest struct {
	Name     string
	Actual   interface{}
	Expected interface{}
}

type TestCase struct {
	Expected any
	Actual   any
}

func runJsonnetFile(t *testing.T, file string) (TestCase, error) {
	repoDir := "/Users/tmillhouse/Developer/work/runbooks/"
	if repoDir == "" {
		var err error
		repoDir, err = filepath.Abs(".")
		require.NoError(t, err, "Failed to get absolute path")
	}

	cmd := exec.Command("/Users/tmillhouse/.local/share/mise/installs/go-jsonnet/0.20.0/bin/jsonnet",
		"-J", "/Users/tmillhouse/Developer/work/runbooks/libsonnet",
		"-J", "/Users/tmillhouse/Developer/work/runbooks/vendor",
		"-J", "/Users/tmillhouse/Developer/work/runbooks/metrics-catalog",
		"-J", "/Users/tmillhouse/Developer/work/runbooks/services",
		"/Users/tmillhouse/Developer/work/runbooks/libsonnet/dashblocks/basic_test.jsonnet",
	)

	output, err := cmd.Output()
	if err != nil {
		return TestCase{}, fmt.Errorf("error: %s, stdout: %s: stderr: %s", err.Error(), cmd.Stdout, cmd.Stderr)
	}

	var result TestCase
	err = json.Unmarshal(output, &result)
	return result, err
}

// Helper function to run a specific test file
func TestSingleFile(t *testing.T) {
	testFile := "/Users/tmillhouse/Developer/work/runbooks/libsonnet/dashblocks/basic_test.jsonnet"
	result, err := runJsonnetFile(t, testFile)
	require.NoError(t, err, "Failed to run test file")

	// var tests map[string]JsonnetTest
	// err = json.Unmarshal(result.([]byte), &tests)
	// require.NoError(t, err, "Failed to unmarshal test cases")

	// for name, test := range tests {
	// 	t.Run(name, func(t *testing.T) {
	expected, err := json.Marshal(result.Expected)
	assert.NoError(t, err)
	actual, err := json.Marshal(result.Actual)
	assert.NoError(t, err)
	assert.JSONEq(t, string(expected), string(actual))
	// })
	// }
}

func TestGraphPanels(t *testing.T) {
	tests := []struct {
		name       string
		actualFile string
		expectFile string
	}{
		{
			name:       "Basic Graph Panel",
			actualFile: "timeseries_basic.jsonnet",
			expectFile: "graph_basic.jsonnet",
		},
		// Add more test cases here
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			actual, err := runJsonnetFile(t, tt.actualFile)
			require.NoError(t, err, "Failed to run actual jsonnet file")

			expected, err := runJsonnetFile(t, tt.expectFile)
			require.NoError(t, err, "Failed to run expected jsonnet file")

			// This will use testify's diff formatting
			assert.Equal(t, expected, actual, "Panel definitions should match")
		})
	}
}
