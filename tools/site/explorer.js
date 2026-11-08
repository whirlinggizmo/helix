// Opens the API reference's tree down to the page shown and marks its type or package, and makes each folder a link to its page. Added to each page by tools/pages.py, after dox's index.js.
$(function () {
	var root = new URL(dox.rootPath, location.href).href;
	if (location.href.indexOf(root) != 0)
		return;
	// A folder's name opens its page: a library's or a package's, and Libraries' and Engines' the overview. Its icon only opens the
	// branch.
	$("#nav li.expando").each(function () {
		var depth = $(this).parents("li.expando").length, href = root + "index.html";
		if (depth > 0) {
			var link = $(this).find("a.treeLink")[0];
			if (link == null)
				return;
			href = root + link.href.slice(root.length).split("/").slice(0, depth + 1).join("/") + "/index.html";
		}
		$(this).children("a.nav-header").attr("href", href).removeAttr("onclick").on("click", function (e) {
			return $(e.target).is("i") ? toggleCollapsed(this) : true;
		});
	});
	$("head").append("<style>#nav a.nav-header.current{background:#999;color:#fff}.dark-theme #nav a.nav-header.current{background:#269}</style>");
	var parts = location.href.slice(root.length).split(/[?#]/)[0].split("/");
	var file = parts.pop();
	var open = function (branch) {
		branch.addClass("expanded").each(function () {
			$(this).find("i").first().removeClass("fa-folder").addClass("fa-folder-open");
		});
	};
	// The top package (helix) is the tree's root. Its packages are each a library's, under Libraries or Engines (tools/pages.py).
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
			return;
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
