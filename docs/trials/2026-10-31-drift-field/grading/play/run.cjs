// run.cjs <page|native> <game> <scenario> [tag]: runs one scenario from scenarios.cjs and prints its JSON result.
const {PageGame, NativeGame} = require('./lib.cjs');
const scenarios = require('./scenarios.cjs');
const fs = require('fs');
const path = require('path');
const [target, n, name, tag0] = process.argv.slice(2);
const tag = tag0 || name;
(async () => {
	const make = (t, opts) => (target == 'page' ? new PageGame(Number(n), t, opts) : new NativeGame(Number(n), t, opts));
	const out = {game: n, target, scenario: name, tag};
	try {
		out.result = await scenarios[name](make, tag, target);
	} catch (e) {
		out.error = e.stack || String(e);
	}
	const file = path.join(__dirname, String(n), `${tag}.${target}.json`);
	fs.writeFileSync(file, JSON.stringify(out, null, 1));
	console.log(JSON.stringify(out).slice(0, 4000));
	process.exit(0);
})();
