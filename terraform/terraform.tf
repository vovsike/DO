terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.66.0"
    }
  }
}

provider "digitalocean" {
  # Configuration options
}

data "digitalocean_sizes" "main" {
  filter {
    key    = "slug"
    values = ["s-2vcpu-4gb"]
  }

  filter {
    key    = "regions"
    values = ["lon1"]
  }
}

resource "digitalocean_droplet" "control_plane" {
  depends_on = [digitalocean_vpc.cluster_vpc]
  image      = "ubuntu-24-04-x64"
  name       = "master-0"
  region     = "lon1"
  ssh_keys   = ["50142925"]
  size       = element(data.digitalocean_sizes.main.sizes, 0).slug
  vpc_uuid   = digitalocean_vpc.cluster_vpc.id
  tags       = ["cluster-control", "k8s-cilium-cluster-master"] # Added Cilium master tag
}

resource "digitalocean_droplet" "wroker-plane" {
  depends_on = [digitalocean_vpc.cluster_vpc]
  count      = 2
  image      = "ubuntu-24-04-x64"
  name       = "worker-${count.index}"
  region     = "lon1"
  ssh_keys   = ["50142925"]
  size       = element(data.digitalocean_sizes.main.sizes, 0).slug
  vpc_uuid   = digitalocean_vpc.cluster_vpc.id
  tags       = ["cluster-worker", "k8s-cilium-cluster-worker"] # Added Cilium worker tag
}

resource "digitalocean_firewall" "ssh" {
  name       = "allow-ssh"
  tags       = ["cluster-worker", "cluster-control"]
  depends_on = [digitalocean_droplet.wroker-plane, digitalocean_droplet.wroker-plane]
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_firewall" "outbound" {
  name       = "outbound-allow-all"
  tags       = ["cluster-worker", "cluster-control"]
  depends_on = [digitalocean_droplet.wroker-plane, digitalocean_droplet.wroker-plane]
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]

  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_vpc" "cluster_vpc" {
  name     = "cluster-vpc"
  region   = "lon1"
  ip_range = "10.0.0.0/20"
}

# 3. Control Firewall
resource "digitalocean_firewall" "cluster_firewall_control" {
  depends_on = [ digitalocean_droplet.control_plane ]
  name = "cluster-firewall-control"
  tags = ["cluster-control"]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "6443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol    = "tcp"
    port_range  = "2379-2380"
    source_tags = ["k8s-cilium-cluster-worker"]
  }

  # Cilium VXLAN overlay (UDP) (FROM WORKERS AND SELF)
  inbound_rule {
    protocol    = "udp"
    port_range  = "8472"
    source_tags = ["k8s-cilium-cluster-worker", "cluster-control"]
  }

  # Cilium health checks (TCP) (FROM WORKERS AND SELF)
  inbound_rule {
    protocol    = "tcp"
    port_range  = "4240"
    source_tags = ["k8s-cilium-cluster-worker", "cluster-control"]
  }

  # Cilium health checks (ICMP) (FROM WORKERS AND SELF)
  inbound_rule {
    protocol    = "icmp"
    source_tags = ["k8s-cilium-cluster-worker", "cluster-control"]
  }

  # Kubelet API (FROM WORKERS AND SELF)
  inbound_rule {
    protocol    = "tcp"
    port_range  = "10250"
    source_tags = ["k8s-cilium-cluster-worker", "cluster-control"]
  }

  # Kube-scheduler (FROM SELF)
  inbound_rule {
    protocol    = "tcp"
    port_range  = "10259"
    source_tags = ["cluster-control"]
  }

  # Kube-controller-manager (FROM SELF)
  inbound_rule {
    protocol    = "tcp"
    port_range  = "10257"
    source_tags = ["cluster-control"]
  }

  # Hubble server and relay
  inbound_rule {
    protocol = "tcp"
    port_range = "4244-4245"
    source_tags = ["k8s-cilium-cluster-worker", "cluster-control"]
  }

  # Mutual Authentication port
  inbound_rule {
    protocol = "tcp"
    port_range = "4250"
    source_tags = ["k8s-cilium-cluster-worker", "cluster-control"]
  }

  # Spire agent health check
  inbound_rule {
    protocol = "tcp"
    port_range = "4251"
    source_tags = ["cluster-control"]
  }

  # Cillium pprof server
  inbound_rule {
    protocol = "tcp"
    port_range = "6060-6062"
    source_tags = ["cluster-control"]
  }

  # Cillium envoy and agent health, agent and opperator gops
  inbound_rule {
    protocol = "tcp"
    port_range = "9878-9891"
    source_tags = ["cluster-control"]
  }

  # Hubble relay gops
  inbound_rule {
    protocol = "tcp"
    port_range = "9893"
    source_tags = ["cluster-control"]
  }

  # Envoy admin-api
  inbound_rule {
    protocol = "tcp"
    port_range = "9901"
    source_tags = ["cluster-control"]
  }

  # Prometheus metrics
  inbound_rule {
    protocol = "tcp"
    port_range = "9962-9964"
    source_tags = ["k8s-cilium-cluster-worker", "cluster-control"]
  }

  # WireGuard encryption tunnel
  inbound_rule {
    protocol = "udp"
    port_range = "51871"
    source_tags = ["k8s-cilium-cluster-worker", "cluster-control"]
  }

    # NodePort Services (keep open for external traffic)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "30000-32767"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "30000-32767"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# 4. Worker Firewall
resource "digitalocean_firewall" "cluster_firewall_worker" {
  depends_on = [ digitalocean_droplet.wroker-plane ]
  name = "cluster-firewall-worker"
  tags = ["cluster-worker"]

  # === CILIUM CORE RULES ===
  # Cilium VXLAN overlay (UDP) (FROM SELF AND MASTERS)
  inbound_rule {
    protocol    = "udp"
    port_range  = "8472"
    source_tags = ["cluster-control", "cluster-worker"]
  }

  # Cilium health checks (TCP) (FROM SELF AND MASTERS)
  inbound_rule {
    protocol    = "tcp"
    port_range  = "4240"
    source_tags = ["cluster-control", "cluster-worker"]
  }

  # Cilium health checks (ICMP) (FROM SELF AND MASTERS)
  inbound_rule {
    protocol    = "icmp"
    source_tags = ["cluster-control", "cluster-worker"]
  }

  # Kubelet API (FROM SELF AND MASTERS)
  inbound_rule {
    protocol    = "tcp"
    port_range  = "10250"
    source_tags = ["cluster-control", "cluster-worker"]
  }

  # Kube Proxy (FROM SELF AND MASTERS)
  inbound_rule {
    protocol    = "tcp"
    port_range  = "10256"
    source_tags = ["cluster-worker"]
  }

  # NodePort Services (keep open for external traffic)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "30000-32767"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "30000-32767"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Hubble server and relay
  inbound_rule {
    protocol = "tcp"
    port_range = "4244-4245"
    source_tags = ["k8s-cilium-cluster-worker", "cluster-control"]
  }

  # Mutual Authentication port
  inbound_rule {
    protocol = "tcp"
    port_range = "4250"
    source_tags = ["k8s-cilium-cluster-worker", "cluster-control"]
  }

  # Spire agent health check
  inbound_rule {
    protocol = "tcp"
    port_range = "4251"
    source_tags = ["k8s-cilium-cluster-worker"]
  }

  # Cillium pprof server
  inbound_rule {
    protocol = "tcp"
    port_range = "6060-6062"
    source_tags = ["k8s-cilium-cluster-worker"]
  }

  # Cillium envoy and agent health, agent and opperator gops
  inbound_rule {
    protocol = "tcp"
    port_range = "9878-9891"
    source_tags = ["k8s-cilium-cluster-worker"]
  }

  # Hubble relay gops
  inbound_rule {
    protocol = "tcp"
    port_range = "9893"
    source_tags = ["k8s-cilium-cluster-worker"]
  }

  # Envoy admin-api
  inbound_rule {
    protocol = "tcp"
    port_range = "9901"
    source_tags = ["k8s-cilium-cluster-worker"]
  }

  # Prometheus metrics
  inbound_rule {
    protocol = "tcp"
    port_range = "9962-9964"
    source_tags = ["k8s-cilium-cluster-worker", "cluster-control"]
  }

  # WireGuard encryption tunnel
  inbound_rule {
    protocol = "udp"
    port_range = "51871"
    source_tags = ["k8s-cilium-cluster-worker", "cluster-control"]
  }
}