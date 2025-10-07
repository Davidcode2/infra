resource "digitalocean_record" "immoly_io_www_A" {
  domain = digitalocean_domain.immoly-io.name
  type = "A"
  name = "www"
  value = var.hetzner_cloud_server_1_ipv4
  ttl    = 1800
}

resource "digitalocean_record" "immoly_io_A" {
  domain = digitalocean_domain.immoly-io.name
  type   = "A"
  name   = "@"
  value  = var.hetzner_cloud_server_1_ipv4
  ttl    = 1800
}

# blog CNAME record
resource "digitalocean_record" "immoly_io_blog_CNAME" {
  domain = digitalocean_domain.immoly-io.name
  type   = "CNAME"
  name   = "blog"
  value  = "${digitalocean_domain.immoly-io.name}."
  ttl    = 30
}

# NS records
resource "digitalocean_record" "immoly_io_ns1" {
  domain = digitalocean_domain.immoly-io.name
  type   = "NS"
  name   = "@"
  value  = "ns1.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "immoly_io_ns2" {
  domain = digitalocean_domain.immoly-io.name
  type   = "NS"
  name   = "@"
  value  = "ns2.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "immoly_io_ns3" {
  domain = digitalocean_domain.immoly-io.name
  type   = "NS"
  name   = "@"
  value  = "ns3.digitalocean.com."
  ttl    = 1800
}

