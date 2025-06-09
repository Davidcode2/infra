terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_domain" "jakob-lingel-dev" {
  name = "jakob-lingel.dev"
}

resource "digitalocean_domain" "schluesselmomente_freiburg_de" {
  name = "schluesselmomente-freiburg.de"
}
