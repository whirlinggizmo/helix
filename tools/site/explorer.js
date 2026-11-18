// Opens the API reference's tree down to the page shown and marks its type or package, and makes each folder a link to its page. Added to each page by tools/build_pages.py, after dox's index.js.
$(function () {
	var root = new URL(dox.rootPath, location.href).href;
	if (location.href.indexOf(root) != 0)
		return;
	// A closed folder's name opens its page: a library's or a package's, and Libraries' and Engines' the overview. An open folder's
	// name closes it, and its icon opens or closes it.
	$("#nav li.expando").each(function () {
		var depth = $(this).parents("li.expando").length, href = root + "index.html";
		if (depth > 0) {
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
	// The members' items are for the search alone (tools/build_pages.py), never shown in the tree.
	$("head").append("<style>#nav a.nav-header.current{background:#999;color:#fff}.dark-theme #nav a.nav-header.current{background:#269}#nav li.member-index{display:none}</style>");
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
		// A page with no folder of its own in the tree (Raylib's module pages, listed beside Raylib) is marked where its folder's would be.
		if (!branch.length)
			break;
		open(branch);
		list = branch.children("ul");
	}
	// A package's page marks its folder.
	if (file == "index.html")
		list.parent("li.expando").children("a.nav-header").addClass("current");
	else
		list.children("li").filter(function () {
			var link = $(this).children("a.treeLink")[0];
			return link != null && link.href.split(/[?#]/)[0] == location.href.split(/[?#]/)[0];
		}).addClass("active");
});
