# Points to business-website ingress
resource "digitalocean_record" "jakob_lingel_dev_www_A" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "A"
  name   = "www"
  #value = var.hetzner_cloud_server_1_ipv4
  value = "49.13.45.106"
  ttl   = 1800
}

# Points to business-website ingress
resource "digitalocean_record" "jakob_lingel_dev_A" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "A"
  name   = "@"
  value  = "49.13.45.106"
  #value  = var.hetzner_cloud_server_1_ipv4
  ttl = 1800
}

# Points to the existing portfolio site (jakob-lingel app)
resource "digitalocean_record" "jakob_lingel_dev_portfolio_A" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "A"
  name   = "portfolio"
  value  = "49.13.45.106"
  #value  = var.hetzner_cloud_server_1_ipv4
  ttl = 1800
}

# immoly CNAME record
resource "digitalocean_record" "jakob_lingel_dev_immoly_CNAME" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "immoly"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}

# blog CNAME record
resource "digitalocean_record" "jakob_lingel_dev_blog_CNAME" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "blog"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}

# www.blog CNAME record
resource "digitalocean_record" "jakob_lingel_dev_www_blog_CNAME" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "www.blog"
  value  = "blog.jakob-lingel.dev."
  ttl    = 1800
}

# google search ownership verification TXT record for immoly
resource "digitalocean_record" "jakob_lingel_dev_immoly_google_verification" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "TXT"
  name   = "@"
  value  = "google-site-verification=-rHm-rqCZBUxj6dSYIX1j722sREMP0wNw9gDLQDWn_Q"
  ttl    = 1800
}

# alemazung CNAME record
resource "digitalocean_record" "jakob_lingel_dev_alemazung" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "alemazung"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}

# analytics CNAME record
resource "digitalocean_record" "jakob_lingel_dev_analytics" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "analytics"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}

# www.analytics CNAME record
resource "digitalocean_record" "jakob_lingel_dev_www_analytics" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "www.analytics"
  value  = "analytics.jakob-lingel.dev."
  ttl    = 1800
}

# uptime CNAME record
resource "digitalocean_record" "jakob_lingel_dev_uptime" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "uptime"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}

# www.uptime CNAME record
resource "digitalocean_record" "jakob_lingel_dev_www_uptime" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "www.uptime"
  value  = "uptime.jakob-lingel.dev."
  ttl    = 1800
}

# argocd CNAME record
resource "digitalocean_record" "jakob_lingel_dev_argocd" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "argocd"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}

# www.argocd CNAME record
resource "digitalocean_record" "jakob_lingel_dev_www_argocd" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "www.argocd"
  value  = "argocd.jakob-lingel.dev."
  ttl    = 1800
}

# home-at-sea CNAME record
resource "digitalocean_record" "jakob_lingel_dev_homeatsea_CNAME" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "homeatsea"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}

# www.homeatsea CNAME record
resource "digitalocean_record" "jakob_lingel_dev_www_homeatsea_CNAME" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "www.homeatsea"
  value  = "homeatsea.jakob-lingel.dev."
  ttl    = 1800
}

# api.homeatsea CNAME record
resource "digitalocean_record" "jakob_lingel_dev_api_homeatsea_CNAME" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "api.homeatsea"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}

# telemetry CNAME record
resource "digitalocean_record" "jakob_lingel_dev_telemetry" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "telemetry"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}

# notifications CNAME record for message-router
resource "digitalocean_record" "jakob_lingel_dev_notifications" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "notifications"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}

# vogthof CNAME record
resource "digitalocean_record" "jakob_lingel_dev_vogthof" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "vogthof"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}

# bueromoebel CNAME record
resource "digitalocean_record" "jakob_lingel_dev_bueromoebel" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "bueromoebel"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}

# www.telemetry CNAME record
resource "digitalocean_record" "jakob_lingel_dev_www_telemetry" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "www.telemetry"
  value  = "telemetry.jakob-lingel.dev."
}

# paperless CNAME record
resource "digitalocean_record" "jakob_lingel_dev_paperless" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "paperless"
  value  = "acer-arch.tailb781ce.ts.net."
  ttl    = 300
}

# NS records
resource "digitalocean_record" "jakob_lingel_dev_ns1" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "NS"
  name   = "@"
  value  = "ns1.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "jakob_lingel_dev_ns2" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "NS"
  name   = "@"
  value  = "ns2.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "jakob_lingel_dev_ns3" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "NS"
  name   = "@"
  value  = "ns3.digitalocean.com."
  ttl    = 1800
}

