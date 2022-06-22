pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "./merkle_proof_verifier.circom";

template CommitmentNullifierHasher() {
    signal input secret;
    signal input index;
    signal input offset;

    signal output commitment;
    signal output nullifier;

    component commitmentHasher = Poseidon(2);
    commitmentHasher.inputs[0] <== secret;
    commitmentHasher.inputs[1] <== 0;
    commitment <== commitmentHasher.out;

    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== secret;
    nullifierHasher.inputs[1] <== 1 + offset + index;
    nullifier <== nullifierHasher.out;
}

template AssociateData(levels) {
    signal input root;
    signal input offset;
    signal input nullifier;
    signal input integrity;

    signal input secret;
    signal input index;
    signal input pathElements[levels];

    component lessThan = LessThan(254);
    lessThan.in[0] <== index;
    lessThan.in[1] <== 2 ** levels;
    lessThan.out === 1;

    component hasher = CommitmentNullifierHasher();
    hasher.secret <== secret;
    hasher.index <== index;
    hasher.offset <== offset;
    hasher.nullifier === nullifier;

    component tree = MerkleProofVerifier(levels);
    tree.leaf <== hasher.commitment;
    tree.index <== index;
    for (var i = 0; i < levels; i++) {
        tree.pathElements[i] <== pathElements[i];
    }
    tree.root === root;

    signal integritySquare;
    integritySquare <== integrity * integrity;
}

component main {public [root, offset, nullifier, integrity]} = AssociateData(20);