-- Turns on LazyVim's bundled language support for your stack: NestJS/React
-- (TypeScript + JavaScript), SQL, Docker, and YAML/JSON config files, plus
-- Go. This is the same thing `:LazyExtras` does when you toggle an entry --
-- these are just declared directly so they're on by default, no manual
-- toggling needed.
--
-- Note: there's no "AWS" entry here because AWS isn't a language LazyVim
-- can give LSP support for -- it's a cloud platform, not a file format.
-- What you actually edit for AWS work (CloudFormation/CDK templates,
-- docker-compose, task defs) is YAML/JSON, which lang.yaml/lang.json below
-- already cover with full schema validation (including AWS's own schemas
-- where SchemaStore has them).
return {
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
  { import = "lazyvim.plugins.extras.lang.docker" },
  { import = "lazyvim.plugins.extras.lang.sql" },
  { import = "lazyvim.plugins.extras.lang.go" },
  { import = "lazyvim.plugins.extras.formatting.prettier" },
  { import = "lazyvim.plugins.extras.linting.eslint" },
}
