// First I create a vpc in which we will place the compute instances
resource "google_compute_network" "chefnet" {
  name = "chefnet"
  auto_create_subnetworks = true
}

//Then I create a firewall and we associate it to my vpc.
resource "google_compute_firewall" "cheffirwall" {
  name = "cheffirewall"
  network = google_compute_network.chefnet.self_link
  source_ranges = ["0.0.0.0/0"]
  allow {
    //I will be allowing http and https to access the chef web UI.
    //Https is also required for chef server to communicate with chef workstation and chef nodes
    //Ssh and rdp to access the instances
    //5985,5986 are the ports used by winrm service in windows. 5985 for communication over http and 5986 for https
    protocol = "TCP"
    ports = [80,443,22,3389,5985,5986]
  }
}

//Let's now start defining the compute instances. First chef server using centos-7
resource "google_compute_instance" "chefserver" {
  zone = var.zone
  machine_type = var.servertype
  name = "chefserver"
  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  network_interface {
    network = google_compute_network.chefnet.self_link
    //Natting the NIC to an ephemeral public IP
    access_config {

    }
  }
}

//Now time for the chef workstation also with centos-7
resource "google_compute_instance" "chefworkstation" {
  zone = var.zone
  machine_type = var.vmtype
  name = "chefworkstation"
  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  network_interface {
    network = google_compute_network.chefnet.self_link
    //Natting the NIC to an ephemeral public IP
    access_config {

    }
  }
}

//let's now create the nodes that chef server will manage. First a linux node, obviously a centos-7 one :)
resource "google_compute_instance" "chefnode" {
  zone = var.zone
  machine_type = var.vmtype
  name = "chefnode"
  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  network_interface {
    network = google_compute_network.chefnet.self_link
    //Natting the NIC to an ephemeral public IP
    access_config {

    }
  }
}

//And a Windows node using windows-server-2012-r2
resource "google_compute_instance" "chefnodewin" {
  zone = var.zone
  machine_type = var.vmtype
  name = "chefnodewin"
  boot_disk {
    initialize_params {
      image = var.imagewin
    }
  }
  network_interface {
    network = google_compute_network.chefnet.self_link
    //Natting the NIC to an ephemeral public IP
    access_config {

    }
  }
}
