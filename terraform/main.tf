# ---------------
# Scaling group & configuration
# ---------------
resource "alicloud_ess_scaling_group" "mk-scaling-group-1" {
  min_size           = 2
  max_size           = 3
  scaling_group_name = "mk-scaling-group-1"
  default_cooldown   = 60
  vswitch_ids        = ["vsw-uf6kasgtw804zlxhbcgvl"]
  removal_policies   = ["OldestScalingConfiguration", "OldestInstance"]
  loadbalancer_ids = [local.loadbalancer_id]
  multi_az_policy    = "BALANCE"
}

data "alicloud_images" "images_ds" {
  owners     = "system"
  name_regex = "^centos_7"
}

output "first_image_id" {
  value = data.alicloud_images.images_ds.images.0.id
}


output "loadbalancer_id_ORG" {
  value = local.loadbalancer_id_ORG
}

output "loadbalancer_id" {
  value = local.loadbalancer_id
}

locals {
  loadbalancer_id_ORG=alicloud_slb_listener.default.id
  loadbalancer_id= regex("^[a-z0-9\\-]+", alicloud_slb_listener.default.id)
}


resource "alicloud_ess_scaling_configuration" "mk-scaling-config-1" {
  scaling_group_id           = alicloud_ess_scaling_group.mk-scaling-group-1.id
  image_id                   = data.alicloud_images.images_ds.images.0.id
  instance_type              = "ecs.t5-lc2m1.nano"
  instance_name              = "mk-scaled-instance-[]"
  security_group_id          = "sg-uf6517hncuo5e26f80sq"
  scaling_configuration_name = "mk-scaling-config-1"
  internet_charge_type       = "PayByTraffic"
  internet_max_bandwidth_in  = 25
  internet_max_bandwidth_out = 25
  system_disk_category       = "cloud_ssd"
  system_disk_size           = 40
  key_name = "marcin.kasinski"
  enable                     = true
  active                     = true
  user_data                  = data.template_file.user_data.rendered
  force_delete               = true

  lifecycle {
    ignore_changes = [user_data]
  }
}

# ---------------
# Scaling rules & alarms
# ---------------
resource "alicloud_ess_scaling_rule" "add-instance" {
  scaling_group_id = alicloud_ess_scaling_group.mk-scaling-group-1.id
  adjustment_type  = "QuantityChangeInCapacity"
  adjustment_value = 1
}

resource "alicloud_ess_scaling_rule" "remove-instance" {
  scaling_group_id = alicloud_ess_scaling_group.mk-scaling-group-1.id
  adjustment_type  = "QuantityChangeInCapacity"
  adjustment_value = -1
}

resource "alicloud_ess_alarm" "mk-alarm-1-add-instance" {
  name                = "mk-alarm-1-add-instance"
  description         = "Add 1 instance when CPU usage >70%"
  alarm_actions       = [alicloud_ess_scaling_rule.add-instance.ari]
  scaling_group_id    = alicloud_ess_scaling_group.mk-scaling-group-1.id
  metric_type         = "system"
  metric_name         = "CpuUtilization"
  period              = 60
  statistics          = "Average"
  threshold           = 70
  comparison_operator = ">="
  evaluation_count    = 2
}

resource "alicloud_ess_alarm" "mk-alarm-2-remove-instance" {
  name                = "mk-alarm-2-remove-instance"
  description         = "Remove 1 instance when CPU usage <10%"
  alarm_actions       = [alicloud_ess_scaling_rule.remove-instance.ari]
  scaling_group_id    = alicloud_ess_scaling_group.mk-scaling-group-1.id
  metric_type         = "system"
  metric_name         = "CpuUtilization"
  period              = 60
  statistics          = "Average"
  threshold           = 10
  comparison_operator = "<="
  evaluation_count    = 2
}

# ---------------
# Queries & outputs
# ---------------
data "template_file" "user_data" {
  template = file("${path.module}/user-data.conf")
}

data "alicloud_images" "ubuntu-18-04-images" {
  owners      = "system"
  name_regex  = "^ubuntu_18_04"
  most_recent = true
}

data "alicloud_instances" "scaled-instances" {
  name_regex = "scaled-instance"
}

output "instances" {
  value = [data.alicloud_instances.scaled-instances.instances]
}
