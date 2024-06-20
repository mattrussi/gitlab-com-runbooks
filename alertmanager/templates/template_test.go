package templates

import (
	"bytes"
	"encoding/json"
	"os"
	"testing"
	"text/template"

	amtemplate "github.com/prometheus/alertmanager/template"
)

// This test pulls some of the functionality from the Alertmanager repository and
// renders the alert templates to ensure they're being parsed as expected.
func TestTemplates(t *testing.T) {
	type args struct {
		dataPath     string
		templatePath string
		templateName string
	}
	tests := []struct {
		name    string
		args    args
		want    string
		wantErr bool
	}{
		{
			name: "gitlab.text_mimir-success",
			args: args{
				dataPath:     "./testdata/mimir-payload.json",
				templatePath: "gitlab.tmpl",
				templateName: "gitlab.text",
			},
			want:    wantFromFile(t, "./testdata/gitlab.text_mimir-success.txt"),
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			data, err := os.ReadFile(tt.args.dataPath)
			if err != nil {
				t.Fatal(err)
			}
			payload := Payload{}
			if err := json.Unmarshal(data, &payload); err != nil {
				t.Fatal(err)
			}

			tmpl := &template.Template{}
			tmpl = tmpl.Funcs(template.FuncMap(amtemplate.DefaultFuncs))
			tmpl, err = tmpl.ParseFiles(tt.args.templatePath)
			if err != nil {
				t.Fatal(err)
			}

			got := bytes.Buffer{}
			if err := tmpl.ExecuteTemplate(&got, tt.args.templateName, payload); err != nil {
				t.Fatal(err)
			}

			if (err != nil) != tt.wantErr {
				t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if got.String() != tt.want {
				t.Errorf("got %s, want %v", got.String(), tt.want)
			}
		})
	}
}

type Payload struct {
	Receiver          string        `json:"receiver"`
	Status            string        `json:"status"`
	Alerts            []Alert       `json:"alerts"`
	GroupLabels       amtemplate.KV `json:"groupLabels"`
	CommonLabels      amtemplate.KV `json:"commonLabels"`
	CommonAnnotations amtemplate.KV `json:"commonAnnotations"`
	ExternalURL       string        `json:"externalURL"`
	Version           string        `json:"version"`
	GroupKey          string        `json:"groupKey"`
}

type Alert struct {
	Status       string        `json:"status"`
	Labels       amtemplate.KV `json:"labels"`
	Annotations  amtemplate.KV `json:"annotations"`
	StartsAt     string        `json:"startsAt"`
	EndsAt       string        `json:"endsAt"`
	GeneratorURL string        `json:"generatorURL"`
}

func wantFromFile(t *testing.T, path string) string {
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return string(data)
}
