resource "digitalocean_record" "mimis_kreativstudio_de_www_A" {
  domain = digitalocean_domain.mimis_kreativstudio_de.name
  type = "A"
  name = "www"
  value = var.hetzner_cloud_server_1_ipv4
  ttl    = 30
}

resource "digitalocean_record" "mimis_kreativstudio_de_A" {
  domain = digitalocean_domain.mimis_kreativstudio_de.name
  type   = "A"
  name   = "@"
  value  = var.hetzner_cloud_server_1_ipv4
  ttl    = 30
}

# NS records
resource "digitalocean_record" "mimis_kreativstudio_de_ns1" {
  domain = digitalocean_domain.mimis_kreativstudio_de.name
  type   = "NS"
  name   = "@"
  value  = "ns1.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "mimis_kreativstudio_de_ns2" {
  domain = digitalocean_domain.mimis_kreativstudio_de.name
  type   = "NS"
  name   = "@"
  value  = "ns2.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "mimis_kreativstudio_de_ns3" {
  domain = digitalocean_domain.mimis_kreativstudio_de.name
  type   = "NS"
  name   = "@"
  value  = "ns3.digitalocean.com."
  ttl    = 1800
}
