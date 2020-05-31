vault {
  renew_token = false
  vault_agent_token_file = "/home/vault/.vault-token"
  retry {
    backoff = "1s"
  }
}
template {
  destination = "/etc/secrets/index.html"
  contents = <<EOF
  <html>
  <body>
  <p>Some secrets:</p>
  {{- with secret "otus/otus-rw/config" }}
  <ul>
  <li><pre>username: {{ .Data.username }}</pre></li>
  <li><pre>password: {{ .Data.password }}</pre></li>
  </ul>
  {{ end }}
  </body>
  </html>
  EOF
}