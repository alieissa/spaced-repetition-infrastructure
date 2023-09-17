terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}
provider "cloudflare" {
  api_key = var.CLOUDFLARE_API_KEY
  email   = "ali.portsudan@gmail.com"
}

data "cloudflare_zone" "sp" {
  name = "spaced-reps.com"
}
resource "cloudflare_record" "sp" {
  name    = "dev-api"
  type    = "CNAME"
  proxied = true
  zone_id = data.cloudflare_zone.sp.zone_id
  value   = var.target
}