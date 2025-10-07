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

resource "digitalocean_domain" "immoly-io" {
  name = "immoly.io"
}

resource "digitalocean_domain" "schluesselmomente_freiburg_de" {
  name = "schluesselmomente-freiburg.de"
}

resource "digitalocean_domain" "teachly_store" {
  name = "teachly.store"
}

resource "digitalocean_domain" "mimis_kreativstudio_de" {
  name = "mimis-kreativstudio.de"
}
