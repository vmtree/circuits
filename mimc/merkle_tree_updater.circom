pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/mimcsponge.circom";

template HashLeftRight() {
    signal input left;
    signal input right;
    signal output hash;

    component hasher = MiMCSponge(2, 220, 1);
    hasher.ins[0] <== left;
    hasher.ins[1] <== right;
    hasher.k <== 0;

    hash <== hasher.outs[0];
}

// s is constrained to be binary, because the value is retrieved from Num2Bits.
// if s is 0 returns in[0]
// if s is 1 returns in[1]
template Selector() {
    signal input in[2];
    signal input s;
    signal output out;

    out <== (in[1] - in[0])*s + in[0];
}

template MerkleTreeUpdater(levels) {
    signal input index;
    signal input leaf;
    signal input filledSubtrees[levels];
    signal output newSubtrees[levels];
    signal output newRoot;

    component hashers[levels];
    component leftSelectors[levels];
    component rightSelectors[levels];
    component indexBits = Num2Bits(levels);
    indexBits.in <== index;

    var zeros[32] = [
        0x1afaac8e3a7748c3f03aabbaf80c9593fb24ab3f9cad18f143a9dcc17849d35c,
        0x0551a3bdc30f8692f5f37ab5175d2877e0aec4ddb31b28678615c5c574bdcb15,
        0x133ca29bafe3665106c090f5030538db3486bf2e913fa2755592db87807dbfbc,
        0x28de5dc92c5127340b6746a6cd21fffea81bd6b8832702fbe48c39d6676db189,
        0x0efa0ca281f28826de3205d872188d38e2b6baed87a7c45255314ca011ac9318,
        0x299329d6b8413840b9179050d9296e677ab5a3899b18fd82fb001230f0b99c5f,
        0x1e1b6cda2bd93da153456b69e4a7c0e82924b2011b20934d08e683e4e99dfe61,
        0x2017136a0741252c1b21ae36c3df97c19137cc1c89c2ee888523663d02b70d1b,
        0x2fe4d873b3087065e9cf5d57b37a691f326b59a2be9ce571bf7ac5aa7c930f11,
        0x2f54a4edf9f3111d7f66a3e477a92b9d9e79c4df0d15b18ee40fc9b8db907373,
        0x22d719998741e04b8052753ece2abc4d40e0a916a4966dab445d233c814b84eb,
        0x007b3db2acd0e3e790ba01871aea4860647607747687f3d0f6ca48715ce17ca5,
        0x1112bc907e8ab44a6bab06d6de75c03dc22ec7caaa02585b73451bc8981db2c1,
        0x2d49fd4645eacc1a860c15c9a622177dfe330ad8483aeca86cbaf1881873b25b,
        0x2e5800f097d961939861c0492f1f87f3fbba08fce9b20128ab591ce63a645e6c,
        0x1fb83fe7fd4b2a17a0aa3956d99040939ae1ead90fa0cb5aa31065919987e4d2,
        0x1ff3cbfad32b3de30b22ca7d6f44c0c46f6b7a80d7725777bcea382617032224,
        0x0ee59ace286991419d97a46411dd9c5082f28e02427c171cd7034ee8c87bf52c,
        0x257bde738852014ce37afe5264772af1f98b816c558762ce358f6335e32ebad6,
        0x0a78cad4aabddd2c50ed181f2ec3afb4462db6f499308a84890f55b65b864c60,
        0x0a6954ccfa0dca9abc94db27523cc32c765e0ee480c5d476339a60127d9df3a7,
        0x1b0b2a42d07f4661d79a7a8291d1b246dadf0c326539f01a11a5a0f7f3acfa3a,
        0x1d7f3514687b0910c18ce5b0f76993972336a4e4c14076b82bc3d32ba341f3a2,
        0x121c02165f10a7a7d47acb28ce004aab05cde7fb4632c9b8702de23f9cbfee6d,
        0x21707aadd4f6140b00b790498cbfa4c004180bd788c3e8a2014b7f18ae2b9e75,
        0x20e8791eb931b7e0c1caa25a0fa7575be183abb56f1a6590dcd7c0183049566d,
        0x2b046c54529080ccfd8369aea4ee2d7d4269cabc0ab89599e5d8e495049ff505,
        0x2aae8efae507440d0d552a07c35c62ae410dc608d1257201a1d504372446cbbc,
        0x121e284193e06f5cb05cc662d06b37cf92936e951b53257546ecb4fe41cb616d,
        0x1c574b3f14952ea54d30f1758ccf081ac153838e28775019601b97fe4b2780f7,
        0x291ac816b1e1505684596206c68d07a6268aa82c305a9d87eb400f68a6bc8351,
        0x2b29195cac67074e6fa65054561aa489e3ebc1ce595270f43a8cee097cb7053
    ];

    for (var i = 0; i < levels; i++) {
        var currentLevelHash = i == 0 ? leaf : hashers[i-1].hash;
        var selector = indexBits.out[i];

        leftSelectors[i] = Selector();
        leftSelectors[i].in[0] <== currentLevelHash;
        leftSelectors[i].in[1] <== filledSubtrees[i];
        leftSelectors[i].s <== selector;
        newSubtrees[i] <== leftSelectors[i].out;

        rightSelectors[i] = Selector();
        rightSelectors[i].in[0] <== zeros[i];
        rightSelectors[i].in[1] <== currentLevelHash;
        rightSelectors[i].s <== selector;

        hashers[i] = HashLeftRight();
        hashers[i].left <== leftSelectors[i].out;
        hashers[i].right <== rightSelectors[i].out;
    }

    newRoot <== hashers[levels - 1].hash;
}