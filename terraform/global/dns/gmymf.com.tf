# Points to nginx ingress controller LoadBalancer
resource "digitalocean_record" "gmymf_com_www_A" {
  domain = digitalocean_domain.gmymf_com.name
  type   = "A"
  name   = "www"
  value  = "49.13.45.106"
  ttl    = 1800
}

# Points to nginx ingress controller LoadBalancer
resource "digitalocean_record" "gmymf_com_A" {
  domain = digitalocean_domain.gmymf_com.name
  type   = "A"
  name   = "@"
  value  = "49.13.45.106"
  ttl    = 1800
}

# NS records
resource "digitalocean_record" "gmymf_com_ns1" {
  domain = digitalocean_domain.gmymf_com.name
  type   = "NS"
  name   = "@"
  value  = "ns1.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "gmymf_com_ns2" {
  domain = digitalocean_domain.gmymf_com.name
  type   = "NS"
  name   = "@"
  value  = "ns2.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "gmymf_com_ns3" {
  domain = digitalocean_domain.gmymf_com.name
  type   = "NS"
  name   = "@"
  value  = "ns3.digitalocean.com."
  ttl    = 1800
}
