// Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
// or more contributor license agreements. Licensed under the Elastic License;
// you may not use this file except in compliance with the Elastic License.

package configuration

import (
	"testing"

	"github.com/elastic/beats/v7/x-pack/elastic-agent/pkg/config"

	"github.com/stretchr/testify/require"
	"gotest.tools/assert"
)

func TestInstrumentationConfig(t *testing.T) {
	tcs := map[string]struct {
		in  map[string]interface{}
		out *InstrumentationConfig
	}{
		"default": {
			in:  map[string]interface{}{},
			out: DefaultInstrumentationConfig(),
		},
		"custom": {
			in: map[string]interface{}{
				"agent.instrumentation": map[string]interface{}{
					"enabled":     true,
					"api_key":     "abc123",
					"environment": "production",
					"hosts":       []string{"https://abc.123.com"},
					"tls": map[string]interface{}{
						"skip_verify":        true,
						"server_certificate": "server_cert",
						"server_ca":          "server_ca",
					},
				},
			},
			out: &InstrumentationConfig{
				Enabled:     true,
				APIKey:      "abc123",
				Environment: "production",
				Hosts:       []string{"https://abc.123.com"},
				TLS: InstrumentationTLS{
					SkipVerify:        true,
					ServerCertificate: "server_cert",
					ServerCA:          "server_ca",
				},
			},
		},
	}

	for name, tc := range tcs {
		t.Run(name, func(t *testing.T) {
			in, err := config.NewConfigFrom(tc.in)
			require.NoError(t, err)

			cfg, err := NewFromConfig(in)
			require.NoError(t, err)
			require.NotNil(t, cfg)
			instCfg := cfg.Settings.InstrumentationConfig
			assert.DeepEqual(t, *tc.out, *instCfg)
		})
	}
}
