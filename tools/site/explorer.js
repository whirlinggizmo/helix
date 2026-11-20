// Opens the API reference's tree down to the page shown and marks its type or package, makes each folder a link to its page, and filters the tree and the search by library. Added to each page by tools/build_pages.py, after dox's index.js.
$(function () {
	// The theme's toggle shows a sun in the dark theme and a moon in the light one.
	var toggled = window.toggleTheme, themeIcon = function () {
		$("#theme-toggle i").toggleClass("fa-sun-o", isDarkTheme()).toggleClass("fa-moon-o", !isDarkTheme());
	};
	window.toggleTheme = function () {
		toggled();
		themeIcon();
	};
	themeIcon();
	var root = new URL(dox.rootPath, location.href).href;
	if (location.href.indexOf(root) != 0)
		return;
	// A closed folder's name opens its page: a library's or a package's, and Libraries' and Engines' the overview. An open folder's
	// name closes it, and its icon opens or closes it.
	$("#nav li.expando").each(function () {
		var depth = $(this).parents("li.expando").length, href = root + "index.html";
		// Raylib's sections open its page, as their folder's name (tools/build_pages.py).
		if ($(this).attr("data-page"))
			href = root + $(this).attr("data-page");
		else if (depth > 0) {
			var link = $(this).find("a.treeLink")[0];
			if (link == null)
				return;
			href = root + link.href.slice(root.length).split("/").slice(0, depth + 1).join("/") + "/index.html";
		}
		var folder = $(this);
		$(this).children("a.nav-header").attr("href", href).removeAttr("onclick").on("click", function (e) {
			return $(e.target).is("i") || folder.hasClass("expanded") ? toggleCollapsed(this) : true;
		});
	});
	// The side column stays in view as the page scrolls.
	// The footer's link, the tables' folder icons and the theme's toggle are light in the dark theme (dox's own are black and #222).
	// The members' items are for the search alone (tools/build_pages.py), never shown in the tree.
	$("head").append("<style>#nav a.nav-header.current{background:#999;color:#fff}.dark-theme #nav a.nav-header.current{background:#269}.dark-theme .copyright a{color:#CCC !important}.dark-theme .table .fa{color:#888}.dark-theme #theme-toggle{color:#CCC !important}#nav li.member-index{display:none}@media (min-width:768px){.main-content .span3{position:sticky;top:20px}}h2.raylib-module{margin-top:2em;border-bottom:2px solid #ccc;padding-bottom:.2em}h4.raylib-group{margin:1.5em 0 .5em;border-bottom:1px solid #ddd;padding-bottom:.2em}.raylib-contents p{margin:.8em 0 .2em}.raylib-contents ul{margin:0 0 0 1em;list-style:none;columns:3;column-gap:2em}.raylib-contents li{break-inside:avoid;margin-bottom:.15em}a.raylib-top{float:right;font-size:14px;font-weight:normal;margin-top:.6em}@media (max-width:767px){.raylib-contents ul{columns:1}}</style>");
	filter();
	var parts = location.href.slice(root.length).split(/[?#]/)[0].split("/");
	var file = parts.pop();
	var open = function (branch) {
		branch.addClass("expanded").each(function () {
			$(this).find("i").first().removeClass("fa-folder").addClass("fa-folder-open");
		});
	};
	// The top package (helix) is the tree's root. Its packages are each a library's, under Libraries or Engines (tools/build_pages.py).
	// The overview opens Libraries and Engines.
	if (parts.length == 0)
		open($("#nav > ul > li.expando"));
	var library = $("#nav li.package-" + parts[1]).first();
	if (!library.length)
		return;
	open(library.parents("li.expando"));
	open(library);
	var list = library.children("ul");
	for (var i = 2; i < parts.length; i++) {
		var branch = list.children("li.expando").filter(function () {
			return $(this).children("a.nav-header").text() == parts[i];
		}).first();
		if (!branch.length)
			break;
		open(branch);
		list = branch.children("ul");
	}
	// A package's page marks its folder, and Raylib's page its sections' folder, opened.
	var page = location.href.split(/[?#]/)[0];
	var sections = list.find("li.expando").filter(function () {
		return $(this).attr("data-page") && root + $(this).attr("data-page") == page;
	});
	if (file == "index.html")
		list.parent("li.expando").children("a.nav-header").addClass("current");
	else if (sections.length) {
		open(sections.parents("li.expando").addBack());
		sections.children("a.nav-header").addClass("current");
	} else
		open(list.find("li").filter(function () {
			var link = $(this).children("a.treeLink")[0];
			return link != null && link.href.split(/[?#]/)[0] == page;
		}).addClass("active").parents("li.expando"));
	// The tree's box scrolls to what's marked.
	var column = $("#nav").closest(".sidebar-nav")[0], marked = $("#nav a.nav-header.current, #nav li.active > a").first();
	if (column && marked.length)
		column.scrollTop = marked.offset().top - $(column).offset().top - column.clientHeight / 3;
});

// The Filter button narrows the tree and the search to the libraries checked in its panel, as GitHub's filters do: none checked shows
// every library, and the button counts those checked. The browser keeps the choice.
function filter() {
	var libraries = $("#nav > ul > li.expando > ul > li.expando"), key = "libraryFilter", checked = [];
	var library = function (item) {
		return (/\bpackage-(\w+)/.exec(item.className) || [])[1];
	};
	try {
		checked = JSON.parse(localStorage.getItem(key)) || [];
	} catch (e) {}
	var panel = $("<div class='library-filter-panel'><div class='library-filter-title'>Filter by library</div><a href='#' class='library-filter-clear'><i class='fa fa-times'></i> Clear filter</a></div>");
	$("#nav > ul > li.expando").each(function () {
		panel.append($("<div class='library-filter-group'></div>").text($(this).children("a.nav-header").text()));
		$(this).find("> ul > li.expando").each(function () {
			var box = $("<input type='checkbox'>").val(library(this)).prop("checked", checked.indexOf(library(this)) >= 0);
			panel.append($("<label></label>").append(box, $("<span></span>").text($(this).children("a.nav-header").text())));
		});
	});
	// dox's box searches: Filter is the button's.
	$("#search").attr("placeholder", "Search (Ctrl+P)");
	var button = $("<button type='button' class='library-filter-button'><i class='fa fa-filter'></i> Filter <span class='library-filter-count'></span></button>");
	$("#searchForm").addClass("library-filter").append(button, panel);
	var apply = function () {
		checked = panel.find("input:checked").map(function () {
			return this.value;
		}).get();
		try {
			localStorage.setItem(key, JSON.stringify(checked));
		} catch (e) {}
		libraries.each(function () {
			$(this).toggleClass("filtered-out", checked.length > 0 && checked.indexOf(library(this)) < 0);
		});
		$("#nav > ul > li.expando").each(function () {
			$(this).toggleClass("filtered-out", !$(this).find("> ul > li.expando").not(".filtered-out").length);
		});
		button.toggleClass("active", checked.length > 0).find(".library-filter-count").text(checked.length || "");
		panel.find(".library-filter-clear").toggle(checked.length > 0);
		window.searchQuery($("#search").val());
	};
	// The search lists what the filter shows: each result's library is its link's first package (helix/raylib/...).
	var search = window.searchQuery;
	window.searchQuery = function (query) {
		search(query);
		var root = new URL(dox.rootPath, location.href).href;
		$("#search-results-list a").removeClass("selected").each(function () {
			if (checked.length && checked.indexOf(this.href.slice(root.length).split("/")[1]) < 0)
				$(this).parent().remove();
		});
		var first = $("#search-results-list a").first().addClass("selected");
		if (first.length)
			$("#searchForm").attr("action", first[0].href);
		else
			$("#searchForm").removeAttr("action");
	};
	button.on("click", function () {
		panel.toggle();
	});
	panel.on("change", "input", apply).on("click", ".library-filter-clear", function () {
		panel.find("input").prop("checked", false);
		apply();
		return false;
	});
	$(document).on("click", function (e) {
		if (!$(e.target).closest(".library-filter").length)
			panel.hide();
	}).on("keydown", function (e) {
		if (e.keyCode == 27)
			panel.hide();
	});
	$("head").append("<style>.filtered-out{display:none !important}#searchForm.library-filter{position:relative;display:flex;gap:6px;align-items:center;margin:0}#searchForm .input-prepend{flex:1;min-width:0;margin:0}.library-filter-button{white-space:nowrap;padding:4px 10px;border:1px solid #ccc;border-radius:6px;background:#f6f8fa;color:#24292f;font-size:13px}.library-filter-button.active{border-color:#0969da;color:#0969da}.library-filter-count{display:none;margin-left:2px;padding:0 6px;border-radius:10px;background:#0969da;color:#fff;font-size:12px}.library-filter-button.active .library-filter-count{display:inline-block}.library-filter-panel{display:none;position:absolute;top:100%;right:0;z-index:1000;margin-top:4px;width:220px;padding:6px 0;border:1px solid #d0d7de;border-radius:6px;background:#fff;box-shadow:0 8px 24px rgba(0,0,0,.15)}.library-filter-panel label{display:flex;gap:8px;align-items:center;margin:0;padding:3px 12px;cursor:pointer}.library-filter-panel label:hover{background:#f6f8fa}.library-filter-panel input{margin:0}.library-filter-title{padding:2px 12px 6px;border-bottom:1px solid #d0d7de;font-weight:bold}.library-filter-group{padding:6px 12px 2px;color:#666;font-size:12px}.library-filter-clear{display:block;padding:4px 12px;border-bottom:1px solid #d0d7de}.dark-theme .library-filter-button{background:#2a2a2a;border-color:#444;color:#ccc}.dark-theme .library-filter-button.active{border-color:#58a6ff;color:#58a6ff}.dark-theme .library-filter-count{background:#1f6feb}.dark-theme .library-filter-panel{background:#222;border-color:#444}.dark-theme .library-filter-title,.dark-theme .library-filter-clear{border-color:#444}.dark-theme .library-filter-panel label:hover{background:#2a2a2a}.dark-theme .library-filter-group{color:#999}</style>");
	apply();
}
