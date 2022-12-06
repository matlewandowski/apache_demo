# VPC
resource "google_compute_network" "demo-vpc" {
  name                    = "demo-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "demo-subnet" {
  name          = "demo-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-central2"
  network       = google_compute_network.demo-vpc.id
}


# VM
resource "google_compute_instance" "demo-vm" {
  name         = "demo-vm"
  machine_type = "e2-micro"
  zone         = "europe-central2-a"
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  # Install Apache
  metadata = {
    startup-script = <<-EOF
    sudo apt update 
    sudo apt install apache2
    sudo ufw allow 'WWW'
  EOF
  }

  network_interface {
    subnetwork = google_compute_subnetwork.demo-subnet.id

    access_config {}
  }
}

# Firewall
resource "google_compute_firewall" "ssh" {
  name = "allow-ssh"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.demo-vpc.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}


resource "google_compute_firewall" "apache" {
  name    = "allow-http"
  network = google_compute_network.demo-vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
}


# Cloud Storage
resource "google_storage_bucket" "default" {
  name          = "matlew-demo-bucket-tfstate"
  force_destroy = false
  location      = "EU"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}