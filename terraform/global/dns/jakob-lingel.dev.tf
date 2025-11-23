resource "digitalocean_record" "jakob_lingel_dev_www_A" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type = "A"
  name = "www"
  value = var.hetzner_cloud_server_1_ipv4
  ttl    = 1800
}

resource "digitalocean_record" "jakob_lingel_dev_A" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "A"
  name   = "@"
  value  = var.hetzner_cloud_server_1_ipv4
  ttl    = 1800
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
  ttl    = 30
}

# www.blog CNAME record
resource "digitalocean_record" "jakob_lingel_dev_blog_CNAME" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "www.blog"
  value  = "blog.jakob-lingel.dev."
  ttl    = 30
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
resource "digitalocean_record" "jakob_lingel_dev_analytics" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "www.analytics"
  value  = "analytics.jakob-lingel.dev."
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
resource "digitalocean_record" "jakob_lingel_dev_argocd" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "www.argocd"
  value  = "argocd.jakob-lingel.dev."
  ttl    = 1800
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

