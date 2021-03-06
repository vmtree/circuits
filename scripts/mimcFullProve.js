const { stringifyBigInts } = require('ffjavascript').utils;
const {
    calculateNextRoot,
    generateProof,
    verifyProof,
    mimcSponge: hasher,
    utils
} = require('vmtree-sdk');

const { unsafeRandomLeaves } = utils;
const wasmFileName = './mimc/out/mass_update_js/mass_update.wasm';
const zkeyFileName = './mimc/out/mass_update.zkey';
const verifierJson = require('../mimc/out/mass_update_verifier.json');

async function main() {
    console.time('mimc mass_update proof time');
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

    const { proof, publicSignals } = await generateProof({input, wasmFileName, zkeyFileName});
    console.timeEnd('mimc mass_update proof time');

    return { proof, publicSignals };
}

main().then(async ({proof, publicSignals}) => {
    console.log(await verifyProof({proof, publicSignals, verifierJson}));
    process.exit();
}).catch(console.error);