# Teachly subdomain records - migrated from expired teachly.store domain

# Main teachly subdomain
resource "digitalocean_record" "teachly_jakob_lingel_dev_A" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "A"
  name   = "teachly"
  value  = "49.13.45.106"
  ttl    = 3600
}

resource "digitalocean_record" "teachly_jakob_lingel_dev_www_A" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "A"
  name   = "www.teachly"
  value  = "49.13.45.106"
  ttl    = 3600
}

# Blog subdomain
resource "digitalocean_record" "teachly_jakob_lingel_dev_blog_CNAME" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "blog.teachly"
  value  = "teachly.jakob-lingel.dev."
  ttl    = 43200
}

resource "digitalocean_record" "teachly_jakob_lingel_dev_www_blog_CNAME" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "www.blog.teachly"
  value  = "blog.teachly.jakob-lingel.dev."
  ttl    = 43200
}

# Portfolio subdomain (Netlify)
resource "digitalocean_record" "teachly_jakob_lingel_dev_portfolio_CNAME" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "portfolio.teachly"
  value  = "clever-pasca-29d973.netlify.app."
  ttl    = 43200
}

# Netlify challenge TXT for portfolio
resource "digitalocean_record" "teachly_jakob_lingel_dev_netlify_challenge_TXT" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "TXT"
  name   = "netlify-challenge.teachly"
  value  = var.portfolio_netlify_challenge_txt
  ttl    = 3600
}

# API subdomain
resource "digitalocean_record" "teachly_jakob_lingel_dev_api_A" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "A"
  name   = "api.teachly"
  value  = "49.13.45.106"
  ttl    = 3600
}

# App subdomain
resource "digitalocean_record" "teachly_jakob_lingel_dev_app_A" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "A"
  name   = "app.teachly"
  value  = "49.13.45.106"
  ttl    = 3600
}
