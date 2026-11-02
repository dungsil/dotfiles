const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');

function loadYaml(location) {
    let directory = path.dirname(location);
    while (true) {
        for (const anchor of [
            path.join(directory, 'package.json'),
            path.join(directory, 'node_modules/@deepseek-ai/dsh/package.json'),
            path.join(directory, 'lib/node_modules/@deepseek-ai/dsh/package.json'),
        ]) {
            if (!fs.existsSync(anchor)) continue;
            if (JSON.parse(fs.readFileSync(anchor, 'utf8')).name !== '@deepseek-ai/dsh') continue;
            const fromDsh = createRequire(anchor);
            return createRequire(fromDsh.resolve('@deepseek-ai/dsh-plugin-manager/package.json'))('yaml');
        }
        const parent = path.dirname(directory);
        if (parent === directory) throw new Error('설치된 DSH의 YAML 라이브러리를 찾지 못했습니다.');
        directory = parent;
    }
}

function mergePatch(YAML, sourceText, targetText) {
    function parse(text) {
        const doc = YAML.parseDocument(text, {
            customTags: [{ tag: 'tag:yaml.org,2002:js', resolve: value => value }],
            uniqueKeys: true,
        });
        if (doc.errors.length) throw new Error(doc.errors[0].message);
        if (doc.warnings.length) throw new Error(doc.warnings[0].message);
        if (!YAML.isSeq(doc.contents)) throw new Error('Cordis 패치는 단일 YAML 배열이어야 합니다.');
        let aliases = 0;
        function expand(node, parents = new Set()) {
            if (!YAML.isNode(node)) return node;
            if (YAML.isAlias(node)) {
                if (++aliases > 1000) throw new Error('YAML 별칭이 너무 많아 병합할 수 없습니다.');
                const resolved = node.resolve(doc);
                if (!resolved) throw new Error('YAML 별칭의 대상을 찾지 못했습니다.');
                return expand(resolved, parents);
            }
            if (parents.has(node)) throw new Error('순환 YAML 별칭은 병합할 수 없습니다.');
            const nested = new Set(parents).add(node);
            const copy = node.clone();
            delete copy.anchor;
            if (YAML.isSeq(node)) copy.items = node.items.map(item => expand(item, nested));
            if (YAML.isMap(node)) {
                copy.items.forEach((pair, index) => {
                    pair.key = expand(node.items[index].key, nested);
                    pair.value = expand(node.items[index].value, nested);
                });
            }
            return copy;
        }
        doc.contents = expand(doc.contents);
        return doc;
    }

    function identity(entry) {
        if (!YAML.isMap(entry)) throw new Error('Cordis 패치의 각 항목은 YAML 매핑이어야 합니다.');
        const id = entry.get('id');
        if (id != null && typeof id !== 'string') throw new Error('Cordis 항목의 id는 문자열이어야 합니다.');
        if (entry.has('insert')) {
            if (!YAML.isSeq(entry.get('insert', true))) throw new Error('Cordis 항목의 insert는 배열이어야 합니다.');
            return `insert:${id ?? ''}`;
        }
        if (!id?.trim()) throw new Error('Cordis 항목에는 id 또는 insert가 필요합니다.');
        return `id:${id}`;
    }

    function validate(entries) {
        const ids = new Set();
        for (const entry of entries.items) {
            const id = identity(entry);
            if (ids.has(id)) throw new Error(`동일한 Cordis 패치 항목이 여러 개여서 병합할 수 없습니다: ${id}`);
            ids.add(id);
            if (entry.has('insert')) validate(entry.get('insert', true));
            if (entry.get('group') === true && YAML.isSeq(entry.get('config', true))) validate(entry.get('config', true));
        }
    }

    function mergeEntries(source, target) {
        for (const entry of source.items) {
            const id = identity(entry);
            const existing = target.items.find(item => identity(item) === id);
            if (!existing) {
                target.add(entry.clone());
                continue;
            }
            if (entry.has('name') && existing.has('name') && entry.get('name') !== existing.get('name')) {
                throw new Error(`동일한 Cordis id가 다른 플러그인을 가리킵니다: ${id}`);
            }
            mergeMap(entry, existing, true);
        }
    }

    function mergeMap(source, target, isEntry = false) {
        for (const pair of source.items) {
            const key = pair.key.value;
            const incoming = pair.value;
            const current = target.get(key, true);
            if (YAML.isMap(incoming) && YAML.isMap(current)) {
                mergeMap(incoming, current);
            } else if (isEntry && (key === 'insert' || (key === 'config' && source.get('group') === true)) &&
                YAML.isSeq(incoming) && YAML.isSeq(current)) {
                mergeEntries(incoming, current);
            } else {
                target.set(key, incoming?.clone() ?? null);
            }
        }
    }

    const source = parse(sourceText);
    const target = parse(targetText);
    validate(source.contents);
    validate(target.contents);
    const original = target.toString();
    mergeEntries(source.contents, target.contents);
    const merged = target.toString();
    if (merged === original) return targetText;
    parse(merged);
    return merged;
}

try {
    const YAML = loadYaml(process.argv[2]);
    const input = JSON.parse(fs.readFileSync(0, 'utf8'));
    process.stdout.write(mergePatch(YAML, input.source, input.target));
} catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
}
