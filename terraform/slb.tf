resource "alicloud_slb" "default" {
  name          = "mk-slb"
  specification = "slb.s1.small"
  vswitch_id    = "vsw-uf6kasgtw804zlxhbcgvl"
  tags = {
    tag_name = "abc"
  }
}




resource "alicloud_slb_listener" "default" {
  load_balancer_id          = alicloud_slb.default.id
  backend_port              = 80
  frontend_port             = 80
  protocol                  = "http"
  bandwidth                 = 10
  sticky_session            = "on"
  sticky_session_type       = "insert"
  cookie_timeout            = 86400
  cookie                    = "testslblistenercookie"
  health_check              = "on"
  health_check_domain       = "ali.com"
  health_check_uri          = "/"
  health_check_connect_port = 80
  healthy_threshold         = 8
  unhealthy_threshold       = 8
  health_check_timeout      = 8
  health_check_interval     = 5
  health_check_http_code    = "http_2xx,http_3xx"
  x_forwarded_for {
    retrive_slb_ip = true
    retrive_slb_id = true
  }
  acl_status      = "on"
  acl_type        = "white"
  acl_id          = alicloud_slb_acl.default.id
  request_timeout = 80
  idle_timeout    = 30
}
resource "alicloud_slb_acl" "default" {
  name       = "mk-alicloud_slb_acl"
  ip_version = "ipv4"
  entry_list {
    entry   = "10.236.96.0/23"
    comment = "first"
  }
  entry_list {
    entry   = "168.10.10.0/24"
    comment = "second"
  }
}