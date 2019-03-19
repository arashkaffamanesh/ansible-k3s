data "template_file" "inventory" {
  template = "${file("${path.module}/tmpl/inventory.tpl")}"

  vars = {
    node_names = "${join(",", module.sample.node_names)}"
    node_ips = "${join(",", module.sample.public_ips)}"
  }

}

resource "local_file" "inventory" {
  content  = "${data.template_file.inventory.rendered}"
  filename = "${path.module}/inventory"
}
