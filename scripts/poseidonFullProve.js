const { stringifyBigInts } = require('ffjavascript').utils;
const {
    calculateNextRoot,
    generateProof,
    poseidon: hasher,
    utils
} = require('vmtjs');

const { unsafeRandomLeaves } = utils;
const wasmFileName = './poseidon/out/mass_update_js/mass_update.wasm';
const zkeyFileName =  './poseidon/out/mass_update.zkey';

async function main() {
    console.time('poseidon proof time');
    const leaves = unsafeRandomLeaves(16);

    const { filledSubtrees: startSubtrees } = calculateNextRoot({ hasher });
    const { root: newRoot, filledSubtrees: endSubtrees } = calculateNextRoot({ hasher, leaves });
    const input = stringifyBigInts({
        startIndex: 0,
        leaves,
        startSubtrees,
        endSubtrees,
        newRoot
    });

    const { proof, publicSignals } = await generateProof(input, wasmFileName, zkeyFileName);
    console.timeEnd('poseidon proof time');

    return { proof, publicSignals };
}

main().then(proof => {
    // console.log(proof);
    process.exit();
}).catch(console.error);