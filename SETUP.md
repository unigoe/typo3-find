# Local demo setup

A complete TYPO3 13 demo site for this extension ("TYPO3 Find") with a Solr 9
index. Everything is set up automatically by `ddev start`.

## Requirements

- [DDEV](https://ddev.com) (with Docker), `ddev start` was tested with v1.25.x
- ~1.5 GB free disk (Docker images + index data)

## Start

```bash
ddev start
```

On the first start this takes a few minutes. A post-start hook
(`.ddev/setup/setup-demo.sh`) runs idempotently on every start and:

1. runs `composer install` if the vendor directory is missing
2. installs TYPO3 (`typo3 setup`) if the database is empty
3. writes the site configuration (`config/sites/find/config.yaml`)
4. imports the demo content (root page, TypoScript template, plugin)
5. fills the Solr core `find` with demo data (skipped when the index has documents)

The setup script is idempotent — repeated `ddev start` runs only run the cheap
checks.

## URLs and credentials

| What | URL | Credentials |
|------|-----|-------------|
| Demo site (search) | https://typo3-find.ddev.site | — |
| TYPO3 backend | https://typo3-find.ddev.site/typo3 | user `admin`, password `Password1!` |
| Solr admin UI | http://localhost:18983/solr | — |
| Solr core | http://localhost:18983/solr/find/select?q=*:* | core name `find` |

The demo content is 2016 universities and academic libraries from
[Wikidata](https://www.wikidata.org) (CC0), located in European countries
(excluding Russia). Try searching for »university«,
filter by the »country« or »type« facets, click a bar in the year histogram
(Chart.js) or use the autocomplete in the search form.

## Data files in this repository

| File | Purpose |
|------|---------|
| `.ddev/docker-compose.solr.yaml` | Solr 9 service, creates the core `find` at startup |
| `.ddev/solr/configset/find/conf/` | Solr `schema.xml` + `solrconfig.xml` for the demo core |
| `.ddev/solr/data/universities.json` | Demo data posted to Solr on first start |
| `.ddev/setup/setup-demo.sh` | Idempotent setup run by the `ddev start` hook |
| `.ddev/setup/demo-content.sql` | Demo content: root page, TypoScript template, plugin |
| `.ddev/setup/sites/find/config.yaml` | Site configuration template |
| `.ddev/setup/fetch-wikidata.py` | Script that generated the demo data from Wikidata |

## Resetting

```bash
ddev stop
docker volume rm ddev-typo3-find_solr-data   # remove the Solr index
ddev rm -R                                   # remove the database and containers
ddev start                                   # full reinstall on the next start
```

## Regenerating the demo data

```bash
python3 .ddev/setup/fetch-wikidata.py .ddev/solr/data/universities.json
```

This queries the [Wikidata Query Service](https://query.wikidata.org) for
universities (Q3918) and academic libraries (Q1664720) located in European
countries (excluding Russia) with country, city, founding year, number of
students and website, then writes a Solr update JSON.
Re-index after changing it: delete the `solr-data` volume (see above) and run
`ddev start`.

## Troubleshooting

- **Port conflict on 8983:** the host port is mapped to `127.0.0.1:18983`
  because other Solr instances often occupy 8983. Change the mapping in
  `.ddev/docker-compose.solr.yaml` if you need a different port. TYPO3 always
  connects to `solr:8983` inside the Docker network.
- **Search returns an error page:** check `ddev logs -s solr` and whether the
  core is up (`curl http://localhost:18983/solr/find/admin/ping`).
- **Setup hook failed:** run it manually with `ddev exec bash
  /var/www/html/.ddev/setup/setup-demo.sh` to see the full output. `ddev start`
  does not fail when the hook fails (`fail_on_hook_fail` is off).
