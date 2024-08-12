resource "aws_security_group" "all_worker_mgmt" {

  name_prefix = "all_worker_management"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id
  
}

resource "aws_vpc_security_group_ingress_rule" "allow_worker_mgmt_ingress1" {
  security_group_id = aws_security_group.all_worker_mgmt.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = 0
  ip_protocol       = "-1"
  to_port           = 0
  description = "allow inbound traffic from eks"
}

resource "aws_vpc_security_group_ingress_rule" "allow_worker_mgmt_ingress2" {
  security_group_id = aws_security_group.all_worker_mgmt.id
  cidr_ipv4         = "172.16.0.0/12"
  from_port         = 0
  ip_protocol       = "-1"
  to_port           = 0
  description = "allow inbound traffic from eks"
}

resource "aws_vpc_security_group_ingress_rule" "allow_worker_mgmt_ingress3" {
  security_group_id = aws_security_group.all_worker_mgmt.id
  cidr_ipv4         = "192.168.0.0/16"
  from_port         = 0
  ip_protocol       = "-1"
  to_port           = 0
  description = "allow inbound traffic from eks"
}

resource "aws_vpc_security_group_egress_rule" "allow_worker_mgmt_eress" {
  description = "allow inbound traffic from eks"
  security_group_id = aws_security_group.all_worker_mgmt.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
  from_port = 0
  to_port = 0
}