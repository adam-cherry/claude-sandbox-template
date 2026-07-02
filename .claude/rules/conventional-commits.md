# Directive: Conventional Commits

## Golden Rule

**Commit messages follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/).** A dry run for later semantic-release tooling — today a manual discipline layer.

## Format

`<type>(<scope>): <description>` — body optional, footer for breaking changes.

## Types (Required)

| Type | When |
|------|------|
| `feat` | New user-visible feature |
| `fix` | Bug fix |
| `docs` | Docs only |
| `refactor` | Restructure without behavior change |
| `test` | Tests added/changed |
| `chore` | Tooling, maintenance, dependencies |
| `perf` | Performance optimization |
| `ci` | CI pipeline change |
| `build` | Build system (Makefile, Dockerfile) |

## Anti-patterns

- `wip:` without a type on main/dev (ok on `feature/*`)
- Lowercase-type violations (`Feat`, `FIX`) — exact lowercase
- Body missing on breaking changes
- Multiple types in one commit (`feat+fix(app):...`) — split
- Commit message > 72 chars in the first line

## Discipline Now = Auto-Tooling Later

A pre-commit hook or semantic-release will automate this discipline later. Write it manually today — clean from day 1.
