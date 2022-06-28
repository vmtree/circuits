pragma circom 2.0.0;

include "./merkle_proof_verifier.circom";

template CommitmentNullifierHasher() {
    signal input secret;
    signal input index;

    signal output commitment;
    signal output nullifier;

    component commitmentHasher = Poseidon(1);
    commitmentHasher.inputs[0] <== secret;
    commitment <== commitmentHasher.out;

    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== secret;
    nullifierHasher.inputs[1] <== index;
    nullifier <== nullifierHasher.out;
}

template MinimalMerkleProof(levels) {
    // public parameters
    signal input root;      // identifies a set of members
    signal input nullifier; // prevents a double spend
    signal input integrity; // for custom contract logic

    // private parameters
    signal input secret; // private key
    signal input index;  // position of the commitment in tree
    signal input pathElements[levels]; // merkle proof elements

    // verify that nullifier is derived from secret
    component hasher = CommitmentNullifierHasher();
    hasher.secret <== secret;
    hasher.index <== index;
    hasher.nullifier === nullifier;

    // verify that commitment is in the merkle tree
    component tree = MerkleProofVerifier(levels);
    tree.leaf <== hasher.commitment;
    tree.index <== index;
    for (var i = 0; i < levels; i++) {
        tree.pathElements[i] <== pathElements[i];
    }
    tree.root === root;

    // enforce an arbitrary constraint on the integrity param
    signal integritySquare;
    integritySquare <== integrity * integrity;
}

component main {public [root, nullifier, integrity]} = MinimalMerkleProof(20);