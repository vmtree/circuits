const { fullProve } = require('snarkjs').groth16;
const { utils, calculateSubtreesV2, poseidon: hasher } = require('vmtjs');
const { stringifyBigInts, unstringifyBigInts } = require('ffjavascript').utils;

const { unsafeRandomLeaves } = utils;
const wasmFileName = './poseidon/out/mass_update_js/mass_update.wasm';
const zkeyFileName =  './poseidon/out/mass_update.zkey';

async function main() {
    console.time('poseidon proof time');
    const leaves = unsafeRandomLeaves(16).map(utils.toFE).map(stringifyBigInts);
    const startSubtrees = calculateSubtreesV2({hasher}).map(utils.toFE).map(stringifyBigInts);
    const endSubtrees = calculateSubtreesV2({hasher, leaves}).map(utils.toFE).map(stringifyBigInts);
    const input = unstringifyBigInts({ startIndex: 0, leaves, startSubtrees, endSubtrees });

    const { proof,publicSignals } = await fullProve(input, wasmFileName, zkeyFileName);
    console.timeEnd('poseidon proof time');

    return { proof, publicSignals };
}

main().then(proof => {
    // console.log(proof);
    process.exit();
}).catch(console.error);