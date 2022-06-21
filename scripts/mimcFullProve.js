const { stringifyBigInts } = require('ffjavascript').utils;
const {
    calculateNextRoot,
    generateProof,
    mimcSponge: hasher,
    utils
} = require('vmtjs');

const { unsafeRandomLeaves } = utils;
const wasmFileName = './mimc/out/mass_update_js/mass_update.wasm';
const zkeyFileName =  './mimc/out/mass_update.zkey';

async function main() {
    console.time('mimc proof time');
    const leaves = unsafeRandomLeaves(10);

    const { filledSubtrees: startSubtrees } = calculateNextRoot({hasher});
    const { root: newRoot, filledSubtrees: endSubtrees } = calculateNextRoot({hasher, leaves});
    const input = stringifyBigInts({
        startIndex: 0,
        leaves,
        startSubtrees,
        endSubtrees,
        newRoot
    });

    const { proof, publicSignals } = await generateProof(input, wasmFileName, zkeyFileName);
    console.timeEnd('mimc proof time');

    return { proof, publicSignals };
}

main().then(proof => {
    // console.log(proof);
    process.exit();
}).catch(console.error);