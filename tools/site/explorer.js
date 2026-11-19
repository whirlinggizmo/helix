// Opens the API reference's tree down to the page shown and marks its type or package, and makes each folder a link to its page. Added to each page by tools/build_pages.py, after dox's index.js.
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
