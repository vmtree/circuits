const { expect } = require('chai');
const { stringifyBigInts } = require('ffjavascript').utils;

const {
    generateProof,
    verifyProof,
    poseidon,
    utils
} = require('vmtree-sdk');

const { unsafeRandomLeaves } = utils;
const wasmFileName = './poseidon/out/proof_of_secret_js/proof_of_secret.wasm';
const zkeyFileName =  './poseidon/out/proof_of_secret.zkey';
const verifierJson = require('../poseidon/out/proof_of_secret_verifier.json');

describe('proof of secret', function() {
    before(() => {
        this.secret = unsafeRandomLeaves(1);
        this.commitment = poseidon(this.secret);
    });
    
    it('should generate a valid zero knowledge proof', async () => {
        console.time('proof of secret proof time');
        const input = stringifyBigInts({
            // public inputs
            commitment: this.commitment,
            // private inputs
            secret: this.secret
        });
        const { proof, publicSignals} = await generateProof({input, wasmFileName, zkeyFileName});
        console.timeEnd('proof of secret proof time');
        expect(await verifyProof({proof, publicSignals, verifierJson})).to.be.true;
    });
});