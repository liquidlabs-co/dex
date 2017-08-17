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
    <p> Token: <pre><code>{{ .IDToken }}</code></pre></p>
    <p> Claims: <pre><code>{{ .Claims }}</code></pre></p>
    {{ if .RefreshToken }}
    <p> Refresh Token: <pre><code>{{ .RefreshToken }}</code></pre></p>
    <form action="{{ .RedirectURL }}" method="post">
      <input type="hidden" name="refresh_token" value="{{ .RefreshToken }}">
      <input type="submit" value="Redeem refresh token">
    </form>
    {{ end }}
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
