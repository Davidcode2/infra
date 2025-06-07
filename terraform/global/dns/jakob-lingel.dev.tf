resource "digitalocean_record" "www" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type = "A"
  name = "www"
  value = var.droplet_ipv4
}

resource "digitalocean_record" "root-a" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "A"
  name   = "@"
  value  = "75.2.60.5"
  ttl    = 3600
}

resource "digitalocean_record" "www-a" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "A"
  name   = "www"
  value  = "75.2.60.5"
  ttl    = 3600
}

resource "digitalocean_record" "blog-cname" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "blog"
  value  = "apex-loadbalancer.netlify.com."
  ttl    = 43200
}

resource "digitalocean_record" "www-blog-cname" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "www.blog"
  value  = "apex-loadbalancer.netlify.com."
  ttl    = 43200
}

resource "digitalocean_record" "ns1" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "NS"
  name   = "@"
  value  = "ns1.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "ns2" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "NS"
  name   = "@"
  value  = "ns2.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "ns3" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "NS"
  name   = "@"
  value  = "ns3.digitalocean.com."
  ttl    = 1800
}
