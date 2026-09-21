-- Demo content for the TYPO3 Find site. Imported by .ddev/setup/setup-demo.sh.
-- Idempotent: INSERT IGNORE keeps existing records.

INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, doktype, is_siteroot, slug, hidden, deleted, sorting, sys_language_uid, perms_userid, perms_groupid, perms_user, perms_group, perms_everybody)
VALUES (1, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'TYPO3 Find', 1, 1, '/', 0, 0, 256, 0, 1, 0, 31, 31, 1);

INSERT IGNORE INTO sys_template (uid, pid, tstamp, crdate, title, root, clear, include_static_file, constants, config, sorting, hidden, deleted)
VALUES (1, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'TYPO3 Find demo', 1, 3, 'EXT:fluid_styled_content/Configuration/TypoScript/,EXT:find/Configuration/TypoScript/', '',
'plugin.tx_find.settings {
	connections {
		default {
			provider = Subugoe\Find\Service\SolrServiceProvider
			options {
				host = solr
				port = 8983
				core = find
				path = /
				timeout = 5
				scheme = http
			}
		}
	}
	standardFields {
		title = title
		snippet = snippet
	}
	queryFields {
		0 {
			autocomplete = 1
			autocompleteDictionary = title
		}
		20 {
			id = year
			type = Range
			extended = 1
			query = year:[%1$s TO %2$s]
			default.0 = 1000
			default.1 = 2100
		}
		30 {
			id = country
			type = SelectFacet
			extended = 1
			facetID = country
			query = country_facet:%s
			phrase = 1
		}
	}
	facets {
		10 {
			id = type
			field = type_facet
		}
		20 {
			id = country
			field = country_facet
			autocomplete = 1
		}
		30 {
			id = city
			field = city_facet
		}
		40 {
			id = year
			field = year
			type = Histogram
			sortOrder = index
			fetchMaximum = 1000
			displayDefault = 1000
			excludeOwnFilter = 1
		}
	}
	sort {
		1 {
			id = default
			sortCriteria = title_sort asc
		}
		2 {
			id = year
			sortCriteria = year desc,title_sort asc
		}
	}
	paging {
		perPage = 20
		menu {
			1 = 10
			2 = 20
			3 = 50
		}
		maximumPerPage = 1000
		detailPagePaging = 1
	}
	highlight {
		default {
			fields.f1 = title
			fragsize = 100
			query = %s
			useQueryTerms = 1
		}
	}
}

tx_find_page = PAGE
tx_find_page {
	typeNum = 1369315139
	10 = EXTBASEPLUGIN
	10 {
		extensionName = Find
		pluginName = Find
	}
	config {
		disableAllHeaderCode = 1
		additionalHeaders.10 {
			header = Content-Type:application/json
			replace = 1
		}
	}
}

page = PAGE
page.typeNum = 0
page.meta.viewport = width=device-width, initial-scale=1
page.includeCSS.demo = EXT:find/Resources/Public/CSS/demo.css

page.10 = COA
page.10 {
	10 = TEXT
	10.value (
<header class="site-header">
	<h1>TYPO3 Find</h1>
	<p>Search universities and academic libraries</p>
</header>
<div class="site-content">
)
	20 < styles.content.get
	30 = TEXT
	30.value = </div>
}
', 256, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, header_layout, colPos, sorting, hidden, deleted, sys_language_uid)
VALUES (1, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'find_find', 'Search', 100, 0, 256, 0, 0, 0);
