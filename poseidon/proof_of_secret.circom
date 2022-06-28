pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template ProofOfSecret() {
    signal input secret;
    signal input commitment;

    component hasher = Poseidon(1);
    hasher.inputs[0] <== secret;
    hasher.out === commitment;
}

component main {public [commitment]} = ProofOfSecret();