resources=(
  "module.dns.digitalocean_record.teachly_store_ns1 teachly.store,1736048762"
  "module.dns.digitalocean_record.teachly_store_ns2 teachly.store,1736048763"
  "module.dns.digitalocean_record.teachly_store_ns3 teachly.store,1736048764"
  "module.dns.digitalocean_record.teachly_store_root_a teachly.store,1736129511"
  "module.dns.digitalocean_record.teachly_store_www_a teachly.store,1736150325"
  "module.dns.digitalocean_record.teachly_store_blog_cname teachly.store,1770244232"
  "module.dns.digitalocean_record.teachly_store_www_blog_cname teachly.store,1770255453"
  "module.dns.digitalocean_record.teachly_store_auth_cname teachly.store,1771365914"
  "module.dns.digitalocean_record.teachly_store_www_auth_cname teachly.store,1771365922"
  "module.dns.digitalocean_record.teachly_store_netlify_challenge_txt teachly.store,1775013430"
  "module.dns.digitalocean_record.teachly_store_portfolio_cname teachly.store,1775013550"
)

for entry in "${resources[@]}"; do
  echo "Importing resource: $entry"
  eval "terraform import $entry"
done 

old_resources=(
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_ns1 schluesselmomente-freiburg.de,1776723512"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_ns2 schluesselmomente-freiburg.de,1776723514"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_ns3 schluesselmomente-freiburg.de,1776723516"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_a schluesselmomente-freiburg.de,1776723817"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_www_a schluesselmomente-freiburg.de,1776724211"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_zoho_verification_txt schluesselmomente-freiburg.de,1777263731"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_spf_txt schluesselmomente-freiburg.de,1777264988"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_mx1 schluesselmomente-freiburg.de,1777264684"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_mx2 schluesselmomente-freiburg.de,1777264705"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_mx3 schluesselmomente-freiburg.de,1777264751"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_zmail_dkim_txt schluesselmomente-freiburg.de,1777264856"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_s1_dkim_txt schluesselmomente-freiburg.de,1777773174"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_api_a schluesselmomente-freiburg.de,1780508291"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_admin_a schluesselmomente-freiburg.de,1781139199"
  "module.dns.digitalocean_record.schluesselmomente_freiburg_de_www_admin_a schluesselmomente-freiburg.de,1781147690"
)
