# NS Records
resource "digitalocean_record" "teachly_store_ns1" {
  domain = digitalocean_domain.teachly_store.name
  type   = "NS"
  name   = "@"
  value  = "ns1.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "teachly_store_ns2" {
  domain = digitalocean_domain.teachly_store.name
  type   = "NS"
  name   = "@"
  value  = "ns2.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "teachly_store_ns3" {
  domain = digitalocean_domain.teachly_store.name
  type   = "NS"
  name   = "@"
  value  = "ns3.digitalocean.com."
  ttl    = 1800
}

# A Records - pointing to k8s cluster
resource "digitalocean_record" "teachly_store_root_a" {
  domain = digitalocean_domain.teachly_store.name
  type   = "A"
  name   = "@"
  value  = "49.13.45.106"
  ttl    = 3600
}

resource "digitalocean_record" "teachly_store_www_a" {
  domain = digitalocean_domain.teachly_store.name
  type   = "A"
  name   = "www"
  value  = "49.13.45.106"
  ttl    = 3600
}

# CNAME Records
resource "digitalocean_record" "teachly_store_blog_cname" {
  domain = digitalocean_domain.teachly_store.name
  type   = "CNAME"
  name   = "blog"
  value  = "@"
  ttl    = 43200
}

resource "digitalocean_record" "teachly_store_www_blog_cname" {
  domain = digitalocean_domain.teachly_store.name
  type   = "CNAME"
  name   = "www.blog"
  value  = "@"
  ttl    = 43200
}

resource "digitalocean_record" "teachly_store_www_auth_cname" {
  domain = digitalocean_domain.teachly_store.name
  type   = "CNAME"
  name   = "www.auth"
  value  = "@"
  ttl    = 43200
}

resource "digitalocean_record" "teachly_store_portfolio_cname" {
  domain = digitalocean_domain.teachly_store.name
  type   = "CNAME"
  name   = "portfolio"
  value  = "clever-pasca-29d973.netlify.app."
  ttl    = 43200
}

# TXT Record
resource "digitalocean_record" "teachly_store_netlify_challenge_txt" {
  domain = digitalocean_domain.teachly_store.name
  type   = "TXT"
  name   = "netlify-challenge"
  value  = var.portfolio_netlify_challenge_txt
  ttl    = 3600
}

# API subdomain A record - points to k8s cluster
resource "digitalocean_record" "teachly_store_api_a" {
  domain = digitalocean_domain.teachly_store.name
  type   = "A"
  name   = "api"
  value  = "49.13.45.106"
  ttl    = 3600
}

# App subdomain A record - points to k8s cluster
resource "digitalocean_record" "teachly_store_app_a" {
  domain = digitalocean_domain.teachly_store.name
  type   = "A"
  name   = "app"
  value  = "49.13.45.106"
  ttl    = 3600
}

# Auth subdomain A record - points to k8s cluster (replaces CNAME)
resource "digitalocean_record" "teachly_store_auth_a" {
  domain = digitalocean_domain.teachly_store.name
  type   = "A"
  name   = "auth"
  value  = "49.13.45.106"
  ttl    = 3600
}
