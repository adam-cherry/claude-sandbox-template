# Genes — Blueprint Lineage Tracking

A repo generated from a versioned blueprint tracks here which blueprint version
served as its basis and which deviations were made deliberately.

## Concept

- **Blueprint** = versioned template (here: `setup/blueprints/`)
- **Gene** = instance of a blueprint in a concrete repo
- **Variations** = deliberate deviations from the blueprint (project-specific)

## Workflow

1. The blueprint is versioned (SemVer)
2. At repo setup, document the version used here (template: `setup/blueprints/_gene_template.md`)
3. On blueprint updates: check the diff between the current gene version and the new blueprint version
4. Adopt relevant updates, keep deliberate variations

## Creating

When instantiating this template, create and fill in an
`agentic_project_structure.gene.md` in this directory from `setup/blueprints/_gene_template.md`.
