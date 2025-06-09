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

# A Records
resource "digitalocean_record" "teachly_store_root_a" {
  domain = digitalocean_domain.teachly_store.name
  type   = "A"
  name   = "@"
  value  = var.digitalocean_droplet_1_ipv4
  ttl    = 3600
}

resource "digitalocean_record" "teachly_store_www_a" {
  domain = digitalocean_domain.teachly_store.name
  type   = "A"
  name   = "www"
  value  = var.digitalocean_droplet_1_ipv4
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

resource "digitalocean_record" "teachly_store_auth_cname" {
  domain = digitalocean_domain.teachly_store.name
  type   = "CNAME"
  name   = "auth"
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
