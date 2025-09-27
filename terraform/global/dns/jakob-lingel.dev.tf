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
  ttl    = 30
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

