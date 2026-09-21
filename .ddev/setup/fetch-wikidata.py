#!/usr/bin/env python3
"""Fetch university library data from Wikidata (CC0) and write a Solr update JSON.

Usage: python3 fetch-wikidata.py [output.json]
Data source: https://query.wikidata.org/sparql - universities (Q3918) and
academic libraries (Q1664720) located in European countries with country, city, founding year, students, website.
"""

import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

QUERY = """
SELECT ?item ?itemLabel ?itemDescription ?type ?countryLabel ?cityLabel ?inception ?coord ?students ?website WHERE {
  ?item wdt:P31 wd:%s.
  BIND("%s" AS ?type)
  ?item wdt:P17 ?country.
  ?country wdt:P30 wd:Q46.
  FILTER(?country != wd:Q159)
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
  OPTIONAL { ?item wdt:P159 ?hq }
  OPTIONAL { ?item wdt:P131 ?admin }
  OPTIONAL { ?item wdt:P571 ?inception }
  OPTIONAL { ?item wdt:P625 ?coord }
  OPTIONAL { ?item wdt:P2196 ?students }
  OPTIONAL { ?item wdt:P856 ?website }
  BIND(COALESCE(?hq, ?admin) AS ?city)
}
LIMIT %d
"""

TYPES = [("Q3918", "University", 2000), ("Q1664720", "Academic library", 1000)]

HEADERS = {"User-Agent": "typo3-find-demo/1.0 (https://github.com/subugoe/typo3-find)"}

POINT_RE = re.compile(r"Point\((-?[\d.]+) (-?[\d.]+)\)")


def fetch(query: str) -> list[dict]:
    url = "https://query.wikidata.org/sparql?" + urllib.parse.urlencode(
        {"query": query, "format": "json"}
    )
    for attempt in range(5):
        try:
            request = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(request, timeout=120) as response:
                return json.load(response)["results"]["bindings"]
        except urllib.error.HTTPError as error:
            if error.code == 429 and attempt < 4:
                time.sleep(30 * (attempt + 1))
                continue
            raise
    return []


def qid(uri: str) -> str:
    return uri.rsplit("/", 1)[-1]


def year_of(date_str: str | None):
    return int(date_str[:4]) if date_str else None


def transform(rows: list[dict]) -> list[dict]:
    documents, seen = [], set()
    for row in rows:
        doc_id = qid(row["item"]["value"])
        if doc_id in seen or "itemLabel" not in row:
            continue
        seen.add(doc_id)

        coord = POINT_RE.match(row["coord"]["value"]) if "coord" in row else None
        document = {
            "id": doc_id,
            "title": row["itemLabel"]["value"],
            "snippet": row.get("itemDescription", {}).get("value"),
            "type": row["type"]["value"],
            "type_facet": row["type"]["value"],
            "year": year_of(row.get("inception", {}).get("value")),
            "students": int(float(row["students"]["value"])) if "students" in row else None,
            "website": row.get("website", {}).get("value"),
            "lat": float(coord.group(2)) if coord else None,
            "lon": float(coord.group(1)) if coord else None,
        }
        for field in ("country", "city"):
            if value := row.get(f"{field}Label", {}).get("value"):
                document[field] = value
                document[f"{field}_facet"] = value
        documents.append(document)
    return documents


def main() -> None:
    rows: list[dict] = []
    for qid_value, label, limit in TYPES:
        query = QUERY % (qid_value, label, limit)
        rows.extend(fetch(query))

    documents = transform(rows)
    output = sys.argv[1] if len(sys.argv) > 1 else "universities.json"
    with open(output, "w", encoding="utf-8") as file:
        json.dump(documents, file, ensure_ascii=False)
    print(f"Wrote {len(documents)} documents to {output}")


if __name__ == "__main__":
    main()
