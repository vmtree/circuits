const { stringifyBigInts } = require('ffjavascript').utils;
const { keccak256 } = require("@ethersproject/solidity");
const { BigNumber } = require("@ethersproject/bignumber");

const {
    MerkleTree,
    generateProof,
    verifyProof,
    poseidon: hasher,
    utils
} = require('vmtree-sdk');

const { unsafeRandomLeaves } = utils;
const wasmFileName = './poseidon/out/associate_data_v2_js/associate_data_v2.wasm';
const zkeyFileName =  './poseidon/out/associate_data_v2.zkey';
const verifierJson = require('../poseidon/out/associate_data_v2_verifier.json');

async function main() {
    console.time('associate data v2 proof time');

    const secret = unsafeRandomLeaves(1)[0];
    const index = 0n;
    const offset = 0n;

    const commitment = hasher([secret]);
    const nullifier = hasher([secret,offset, index]);

    const merkleTree = new MerkleTree({ hasher, leaves: [commitment] });
    const root = merkleTree.root;
    const { pathElements } = merkleTree.proof(commitment);

    // simulate a mixer withdrawal. this integrity value is supposed to be 
    // hardcoded in the mixer's solidity contract.
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
        // public inputs
        root,
        offset,
        nullifier,
        integrity,
        // private inputs
        secret,
        index,
        pathElements
    });

    const { proof, publicSignals } = await generateProof({input, wasmFileName, zkeyFileName});
    console.timeEnd('associate data v2 proof time');
    return { proof, publicSignals };
}

main().then(async ({proof, publicSignals}) => {
    console.log(await verifyProof({proof, publicSignals, verifierJson}));
    process.exit();
}).catch(console.error);