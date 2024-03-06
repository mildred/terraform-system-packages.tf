terraform {
  required_providers {
    sys = {
      source = "mildred/sys"
    }
    uname = {
      source = "julienlevasseur/uname"
      version = "0.1.1"
    }
  }
  required_version = ">= 0.13"
}

