// Opens the API reference's tree down to the page shown and marks its type. Added to each page by tools/pages.py, after dox's index.js.
$(function () {
	var root = new URL(dox.rootPath, location.href).href;
	if (location.href.indexOf(root) != 0)
		return;
	var parts = location.href.slice(root.length).split(/[?#]/)[0].split("/");
	var file = parts.pop();
	// The top package (helix) is the tree's root, so the path starts below it.
	var list = $("#nav > ul");
	for (var i = 1; i < parts.length; i++) {
		var branch = list.children("li.expando").filter(function () {
			return $(this).children("a.nav-header").text() == parts[i];
		}).first();
		if (!branch.length)
			return;
		branch.addClass("expanded");
		branch.find("i").first().removeClass("fa-folder").addClass("fa-folder-open");
		list = branch.children("ul");
	}
	if (file != "index.html")
		list.children("li").has("a.treeLink").filter(function () {
			return $(this).children("a.treeLink")[0].href.split(/[?#]/)[0] == location.href.split(/[?#]/)[0];
		}).addClass("active");
});
