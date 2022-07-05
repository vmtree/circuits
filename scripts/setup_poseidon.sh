#!/bin/bash

if [ ! -f "./powers_of_tau/powersOfTau28_hez_final_17.ptau" ]
then
    echo "[SETUP] - Downloading powersOfTau28_hez_final_17.ptau file"
    echo "[SETUP] - See https://github.com/iden3/snarkjs for a list of ptau files."
    wget \
        https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_17.ptau \
        -O ./powers_of_tau/powersOfTau28_hez_final_17.ptau
else
    echo "[SETUP] - Powers of tau detected, skipping download"
fi

echo "[SETUP] - Compiling circuit"
circom -o ./poseidon/out --r1cs --wasm --sym ./poseidon/mass_update.circom

echo "[SETUP] - Setting up phase 2 ceremony"
snarkjs g16s \
    ./poseidon/out/mass_update.r1cs \
    ./powers_of_tau/powersOfTau28_hez_final_17.ptau \
    ./poseidon/out/mass_update_0000.zkey

echo "[SETUP] - Contributing to the ceremony"
snarkjs zkc \
    ./poseidon/out/mass_update_0000.zkey \
    ./poseidon/out/mass_update.zkey \
    -e='unique new york'

echo "[SETUP] - Exporting verification key to json"
snarkjs zkev \
    ./poseidon/out/mass_update.zkey \
    ./poseidon/out/mass_update_verifier.json

echo "[SETUP] - Exporting verification key to solidity"
snarkjs zkesv \
    ./poseidon/out/mass_update.zkey \
    ./poseidon/out/mass_update_verifier.sol