terraform {
  required_providers {
    apko = { source = "chainguard-dev/apko" }
  }
}

locals {
  components = toset([
    "earlystopping",
    "suggestion-hyperband",
    "suggestion-hyperopt",
    "suggestion-nas-darts",
    "suggestion-optuna-enas",
    "suggestion-pbt-enas",
    "suggestion-skopt-enas",
  ])

  packages = merge(
    { for k in local.components : k => k },
    {
      "earlystopping"          = "katib-earlystopping"
      "suggestion-hyperband"   = "katib-suggestion-hyperband"
      "suggestion-hyperopt"    = "katib-suggestion-hyperopt"
      "suggestion-nas-darts"   = "katib-suggestion-nas-darts"
      "suggestion-optuna-enas" = "katib-suggestion-optuna-enas"
      "suggestion-pbt-enas"    = "katib-suggestion-pbt-enas"
      "suggestion-skopt-enas"  = "katib-suggestion-skopt-enas"
    },
  )

  repositories = merge(
    { for k in local.components : k => k },
    {
      "earlystopping"          = "${var.target_repository}-earlystopping"
      "suggestion-hyperband"   = "${var.target_repository}-suggestion-hyperband"
      "suggestion-hyperopt"    = "${var.target_repository}-suggestion-hyperopt"
      "suggestion-nas-darts"   = "${var.target_repository}-suggestion-nas-darts"
      "suggestion-optuna-enas" = "${var.target_repository}-suggestion-optuna-enas"
      "suggestion-pbt-enas"    = "${var.target_repository}-suggestion-pbt-enas"
      "suggestion-skopt-enas"  = "${var.target_repository}-suggestion-skopt-enas"
    },
  )
}

variable "target_repository" {
  description = "The docker repo into which the image and attestations should be published."
}

module "dev" {
  source = "../../tflib/dev-subvariant"
}

module "latest" {
  for_each = local.repositories
  source   = "../../tflib/publisher"

  name = basename(path.module)

  target_repository = each.value
  config            = file("${path.module}/configs/latest.${each.key}.apko.yaml")
}

module "latest-dev" {
  for_each = local.repositories
  source   = "../../tflib/publisher"

  name = basename(path.module)

  target_repository = each.value
  config            = jsonencode(module.latest[each.key].config)
  extra_packages    = module.dev.extra_packages
}

module "version-tags" {
  for_each = local.packages
  source   = "../../tflib/version-tags"

  package = each.value
  config  = module.latest[each.key].config
}

module "test-latest" {
  source = "./tests"

  digests = { for k, v in module.latest : k => v.image_ref }
}

module "tagger" {
  for_each = local.components
  source   = "../../tflib/tagger"

  depends_on = [module.test-latest]

  tags = merge(
    { for t in toset(concat(["latest"], module.version-tags[each.key].tag_list)) : t => module.latest[each.key].image_ref },
    { for t in toset(concat(["latest"], module.version-tags[each.key].tag_list)) : "${t}-dev" => module.latest-dev[each.key].image_ref },
  )
}
