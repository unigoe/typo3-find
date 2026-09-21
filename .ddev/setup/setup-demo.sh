#!/usr/bin/env bash
# Idempotent demo setup for the TYPO3 Find site. Runs on every `ddev start`.
# 1. composer install (fresh clone)  2. TYPO3 setup (empty DB)
# 3. site config  4. demo content  5. Solr index
set -euo pipefail
cd /var/www/html

DB_DSN="mysql:host=db;dbname=db"

# 1. Composer dependencies (fresh clone: .Build does not exist yet)
if [ ! -f .Build/bin/typo3 ]; then
  composer install --no-interaction --no-progress
fi

# 2. TYPO3 setup when the database is empty or has no admin user
if ! php -r "
  try {
    \$pdo = new PDO('${DB_DSN}', 'db', 'db');
    \$hasTables = (bool) \$pdo->query(\"SHOW TABLES LIKE 'pages'\")->fetchColumn();
    \$hasAdmin = \$hasTables ? (bool) \$pdo->query('SELECT 1 FROM be_users WHERE admin = 1')->fetchColumn() : false;
    exit(\$hasTables && \$hasAdmin ? 0 : 1);
  } catch (Throwable \$e) {
    exit(1);
  }
"; then
  .Build/bin/typo3 setup --force --no-interaction \
    --driver=mysqli --host=db --port=3306 --dbname=db --username=db --password=db \
    --admin-username=admin --admin-user-password='Password1!' \
    --project-name='TYPO3 Find' --server-type=other
fi

# 3. Site configuration
if [ ! -f config/sites/find/config.yaml ]; then
  mkdir -p config/sites/find
  cp .ddev/setup/sites/find/config.yaml config/sites/find/config.yaml
fi

# 3b. Allow search queries without cHash (required for the find extension)
if ! grep -q "pageNotFoundOnCHashError" config/system/settings.php 2>/dev/null; then
  php -r '
    $file = "config/system/settings.php";
    $settings = @include $file;
    if (!is_array($settings)) { fwrite(STDERR, "invalid settings.php\n"); exit(1); }
    $settings["FE"]["cacheHash"]["requireCHashArgument"] = false;
    $settings["FE"]["cacheHash"]["enforceValidation"] = false;
    $settings["FE"]["pageNotFoundOnCHashError"] = false;
    file_put_contents($file, "<?php\nreturn " . var_export($settings, true) . ";\n");
  '
fi

# 4. Demo content (root page, template, plugin)
if ! php -r "
  try {
    \$pdo = new PDO('${DB_DSN}', 'db', 'db');
    \$found = \$pdo->query(\"SELECT uid FROM pages WHERE uid = 1 AND title = 'TYPO3 Find'\")->fetchColumn();
    exit(\$found ? 0 : 1);
  } catch (Throwable \$e) {
    exit(1);
  }
"; then
  php -r "
    \$pdo = new PDO('${DB_DSN}', 'db', 'db', [PDO::MYSQL_ATTR_MULTI_STATEMENTS => true]);
    \$pdo->exec(file_get_contents('.ddev/setup/demo-content.sql'));
    echo 'Demo content imported.' . PHP_EOL;
  "
  .Build/bin/typo3 cache:flush
fi

# 5. Fill the Solr index with the demo data (skipped when documents are present)
for _ in $(seq 1 30); do
  curl -sf http://solr:8983/solr/find/admin/ping >/dev/null 2>&1 && solrUp=1 && break
  sleep 2
done
if [ "${solrUp:-0}" = "1" ]; then
  count=$(curl -s 'http://solr:8983/solr/find/select?q=*:*&rows=0&wt=json' | grep -o '"numFound":[0-9]*' | head -1 | cut -d: -f2 || true)
  if [ "${count:-1}" = "0" ]; then
    curl -s -X POST -H 'Content-Type: application/json' \
      --data-binary @.ddev/solr/data/universities.json \
      'http://solr:8983/solr/find/update?commit=true&wt=json' >/dev/null
    echo 'Solr index filled.'
  fi
else
  echo 'Solr not reachable, skipping index.' >&2
fi
