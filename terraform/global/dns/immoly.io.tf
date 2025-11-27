resource "digitalocean_record" "immoly_io_www_A" {
  domain = digitalocean_domain.immoly-io.name
  type = "A"
  name = "www"
  value  = "49.13.45.106"
  #value = var.hetzner_cloud_server_1_ipv4
  #value = hcloud_load_balancer.k8s_lb.ipv4
  ttl    = 1800
}

resource "digitalocean_record" "immoly_io_A" {
  domain = digitalocean_domain.immoly-io.name
  type   = "A"
  name   = "@"
  value  = "49.13.45.106"
  #value = var.hetzner_cloud_server_1_ipv4
  #value = hcloud_load_balancer.k8s_lb.ipv4
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

# alemazung CNAME record
resource "digitalocean_record" "immoly_io_alemazung_CNAME" {
  domain = digitalocean_domain.immoly-io.name
  type   = "CNAME"
  name   = "alemazung"
  value  = "${digitalocean_domain.immoly-io.name}."
  ttl    = 30
}

# www.alemazung CNAME record
resource "digitalocean_record" "immoly_io_alemazung_CNAME" {
  domain = digitalocean_domain.immoly-io.name
  type   = "CNAME"
  name   = "www.alemazung"
  value  = "${digitalocean_domain.immoly-io.name}."
  ttl    = 30
}

# google search ownership verification TXT record for immoly
resource "digitalocean_record" "immoly_io_google_verification" {
  domain = digitalocean_domain.immoly-io.name
  type   = "TXT"
  name   = "@"
  value  = "google-site-verification=4JEzmJ-pAhowMTRZCZNCTa-nrL2HKT3casSXqD21GZc"
  ttl    = 1800
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

