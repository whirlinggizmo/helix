// The Node tools' command lines (docs/CONVENTIONS.md, "Every tool answers --help"), as tools/cli.py is the Python ones': --help prints the
// tool's leading comment and its usage; an option it doesn't take (a word starting with -) is refused, and so are too few arguments
// (exit 2). Imported by the tools, not run.
const fs = require('fs');
const path = require('path');

// The arguments of the tool at file, named by names (a last name ending in ... takes the rest), each one given, as an array.
function args(file, names) {
	const given = process.argv.slice(2), rest = names.length > 0 && names[names.length - 1].endsWith('...');
	const usage = `usage: node ${path.relative(process.cwd(), file)} ${names.map(n => n.toUpperCase()).join(' ')}`;
	if (given.includes('--help') || given.includes('-h')) {
		const help = fs.readFileSync(file, 'utf8').split('\n').filter((l, i, all) => all.slice(0, i + 1).every(x => x.startsWith('//')))
			.map(l => l.replace(/^\/\/ ?/, '')).join('\n');
		console.log(`${usage}\n\n${help}`);
		process.exit(0);
	}
	const option = given.find(a => a.startsWith('-'));
	if (option !== undefined || given.length < names.length - (rest ? 1 : 0) || (!rest && given.length > names.length)) {
		console.error(`${usage}\n${path.basename(file)}: ${option !== undefined ? `unknown option ${option}` : 'expected ' + names.join(', ')}`);
		process.exit(2);
	}
	return given;
}

module.exports = {args};

if (require.main === module) {
	if (process.argv.includes('--help') || process.argv.includes('-h')) {
		console.log('usage: a module, required by the Node tools: nothing to run\n');
		console.log(fs.readFileSync(__filename, 'utf8').split('\n').filter((l, i, all) => all.slice(0, i + 1).every(x => x.startsWith('//')))
			.map(l => l.replace(/^\/\/ ?/, '')).join('\n'));
		process.exit(0);
	}
	console.error('cli.cjs: a module the Node tools require, with nothing to run of its own (--help says what it is)');
	process.exit(2);
}
