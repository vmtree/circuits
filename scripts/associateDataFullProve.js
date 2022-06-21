const { stringifyBigInts } = require('ffjavascript').utils;
const { keccak256 } = require("@ethersproject/solidity");
const { BigNumber } = require("@ethersproject/bignumber");

const {
    MerkleTree,
    generateProof,
    verifyProof,
    poseidon: hasher,
    utils
} = require('vmtjs');

const { unsafeRandomLeaves } = utils;
const wasmFileName = './poseidon/out/associate_data_js/associate_data.wasm';
const zkeyFileName =  './poseidon/out/associate_data.zkey';
const verifierJson = require('../poseidon/out/associate_data_verifier.json');

async function main() {
    console.time('associate data proof time');

    const offset = 0;
    const index = 0;
    const secret = unsafeRandomLeaves(1)[0];
    const commitment = hasher([secret, 0n]);
    const nullifier = hasher([secret, 1n]);
    const merkleTree = new MerkleTree({ hasher, leaves: [commitment] });
    const root = merkleTree.root;
    const { pathElements } = merkleTree.proof(commitment);

    // simulate a mixer withdrawal
    const integrity = BigNumber.from(keccak256(
        [
            'address', // recipient
            'address', // relayer
            'uint',    // fee in token
            'uint'     // refund in eth
        ],
        [
            '0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
            '0x7777777777777777777777777777777777777777',
            '10000000000000000',
            '1000000000000000'
        ]
    )).mod(utils.F.p.toString()).toString();

    const input = stringifyBigInts({
        root,
        offset,
        nullifier,
        integrity,
        secret,
        index,
        pathElements
    });

    const { proof, publicSignals } = await generateProof(input, wasmFileName, zkeyFileName);
    console.timeEnd('associate data proof time');
    return { proof, publicSignals };
}

main().then(async ({proof, publicSignals}) => {
    console.log(await verifyProof({proof, publicSignals, verifierJson}));
    process.exit();
}).catch(console.error);