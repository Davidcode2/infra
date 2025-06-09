# NS records
resource "digitalocean_record" "schluesselmomente_freiburg_de_ns1" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "NS"
  name   = "@"
  value  = "ns1.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "schluesselmomente_freiburg_de_ns2" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "NS"
  name   = "@"
  value  = "ns2.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "schluesselmomente_freiburg_de_ns3" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "NS"
  name   = "@"
  value  = "ns3.digitalocean.com."
  ttl    = 1800
}

# A records
resource "digitalocean_record" "schluesselmomente_freiburg_de_root_a" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "A"
  name   = "@"
  value  = var.digitalocean_droplet_1_ipv4
  ttl    = 3600
}

resource "digitalocean_record" "schluesselmomente_freiburg_de_www_a" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "A"
  name   = "www"
  value  = var.digitalocean_droplet_1_ipv4
  ttl    = 3600
}

resource "digitalocean_record" "schluesselmomente_freiburg_de_api_a" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "A"
  name   = "api"
  value  = var.digitalocean_droplet_1_ipv4
  ttl    = 3600
}

resource "digitalocean_record" "schluesselmomente_freiburg_de_admin_a" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "A"
  name   = "admin"
  value  = var.hetzner_cloud_server_1_ipv4
  ttl    = 3600
}

resource "digitalocean_record" "schluesselmomente_freiburg_de_www_admin_a" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "A"
  name   = "www.admin"
  value  = var.hetzner_cloud_server_1_ipv4
  ttl    = 3600
}

# TXT records
resource "digitalocean_record" "schluesselmomente_freiburg_de_zoho_verification_txt" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "TXT"
  name   = "@"
  value  = var.schluesselmomente_freiburg_de_zoho_verification_TXT_value
  ttl    = 3600
}

resource "digitalocean_record" "schluesselmomente_freiburg_de_spf_txt" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "TXT"
  name   = "@"
  value  = var.schluesselmomente_freiburg_de_SPF_TXT_value
  ttl    = 3600
}

resource "digitalocean_record" "schluesselmomente_freiburg_de_zmail_dkim_txt" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "TXT"
  name   = "zmail._domainkey"
  value  = var.schluesselmomente_freiburg_de_ZMAIL_DKIM_value
  ttl    = 3600
}

resource "digitalocean_record" "schluesselmomente_freiburg_de_s1_dkim_txt" {
  domain = digitalocean_domain.schluesselmomente_freiburg_de.name
  type   = "TXT"
  name   = "s1._domainkey"
  value  = var.schluesselmomente_freiburg_de_DKIM_value
  ttl    = 3600
}

# MX records
resource "digitalocean_record" "schluesselmomente_freiburg_de_mx1" {
  domain   = digitalocean_domain.schluesselmomente_freiburg_de.name
  type     = "MX"
  name     = "@"
  value    = "mx.zoho.eu."
  priority = 10
  ttl      = 3600
}

resource "digitalocean_record" "schluesselmomente_freiburg_de_mx2" {
  domain   = digitalocean_domain.schluesselmomente_freiburg_de.name
  type     = "MX"
  name     = "@"
  value    = "mx2.zoho.eu."
  priority = 20
  ttl      = 3600
}

resource "digitalocean_record" "schluesselmomente_freiburg_de_mx3" {
  domain   = digitalocean_domain.schluesselmomente_freiburg_de.name
  type     = "MX"
  name     = "@"
  value    = "mx3.zoho.eu."
  priority = 50
  ttl      = 3600
}
