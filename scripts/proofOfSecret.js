const { stringifyBigInts } = require('ffjavascript').utils;

const {
    generateProof,
    verifyProof,
    poseidon: hasher,
    utils
} = require('vmtree-sdk');

const { unsafeRandomLeaves } = utils;
const wasmFileName = './poseidon/out/proof_of_secret_js/proof_of_secret.wasm';
const zkeyFileName =  './poseidon/out/proof_of_secret.zkey';
const verifierJson = require('../poseidon/out/proof_of_secret_verifier.json');

async function main() {
    console.time('proof of secret proof time');

    const secret = unsafeRandomLeaves(1)[0];
    const commitment = hasher([secret]);

    const input = stringifyBigInts({
        // public inputs
        commitment,
        // private inputs
        secret
    });

    const { proof, publicSignals } = await generateProof({input, wasmFileName, zkeyFileName});
    console.timeEnd('proof of secret proof time');
    return { proof, publicSignals };
}

main().then(async ({proof, publicSignals}) => {
    console.log(await verifyProof({proof, publicSignals, verifierJson}));
    process.exit();
}).catch(console.error);