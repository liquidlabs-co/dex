package main

import (
	"html/template"
	"log"
	"net/http"
)

var indexTmpl = template.Must(template.New("index.html").Parse(`<html>
  <head>
  <link rel="stylesheet" href="/static/unite.css">
  <link rel="stylesheet" href="/static/stylesheet.css">
  </head>
  <body>
    <div class="center">
    <form action="/login" method="post" id="login">
        <input type="hidden" name="cross_client" placeholder="list of client-ids">
        <input type="hidden" name="extra_scopes" placeholder="list of scopes">
        <input type="hidden" name="offline_access" value="yes" checked>
    <button type="submit" form="login" class="bttn-unite bttn-lg bttn-primary"> Log into Kubernetes </button>
    </form>
    </div>
  </body>
</html>`))

func renderIndex(w http.ResponseWriter) {
	renderTemplate(w, indexTmpl, nil)
}

type tokenTmplData struct {
	IDToken      string
	RefreshToken string
	RedirectURL  string
	Claims       string
}

var tokenTmpl = template.Must(template.New("token.html").Parse(`<html>
  <head>
  <link rel="stylesheet" href="/static/stylesheet.css">
  </head>
  <body>
    <div>
      <p> First time setting up?  Use these Commands!
      <pre><code>
      export K8S_TOKEN={{ .IDToken }}
      export K8S_CLUSTER_NAME=hosting.gigster.com
      export K8S_CA_FILE=~/${K8S_CLUSTER_NAME}.cert
      curl -o ${K8S_CA_FILE} --noproxy '*' -k https://s3.amazonaws.com/gigster-network-cluster-keys/hosting.gigster.com/cluster.ca.cert
      kubectl config set-credentials github_profile --token=${K8S_TOKEN}
      kubectl config set-cluster ${K8S_CLUSTER_NAME} --certificate-authority=${K8S_CA_FILE} --server=https://api.${K8S_CLUSTER_NAME} --embed-certs=true
      kubectl config set-context gigsternetwork --user=github_profile --cluster=${K8S_CLUSTER_NAME}
      kubectl config use-context gigsternetwork
      </code></pre>

      <p> Refreshing your login? Use these Commands!
      <pre><code>
      export K8S_TOKEN={{ .IDToken }}
      kubectl config set-credentials github_profile --token=${K8S_TOKEN}
      kubectl config use-context gigsternetwork
      </code></pre>
    </div>
  </body>
</html>
`))

func renderToken(w http.ResponseWriter, redirectURL, idToken, refreshToken string, claims []byte) {
	renderTemplate(w, tokenTmpl, tokenTmplData{
		IDToken:      idToken,
		RefreshToken: refreshToken,
		RedirectURL:  redirectURL,
		Claims:       string(claims),
	})
}

func renderTemplate(w http.ResponseWriter, tmpl *template.Template, data interface{}) {
	err := tmpl.Execute(w, data)
	if err == nil {
		return
	}

	switch err := err.(type) {
	case *template.Error:
		// An ExecError guarantees that Execute has not written to the underlying reader.
		log.Printf("Error rendering template %s: %s", tmpl.Name(), err)

		// TODO(ericchiang): replace with better internal server error.
		http.Error(w, "Internal server error", http.StatusInternalServerError)
	default:
		// An error with the underlying write, such as the connection being
		// dropped. Ignore for now.
	}
}
