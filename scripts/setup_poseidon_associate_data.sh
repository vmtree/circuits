#!/bin/bash

if [ ! -f "./powers_of_tau/powersOfTau28_hez_final_13.ptau" ]
then
    echo "[SETUP] - Downloading powersOfTau28_hez_final_13.ptau file"
    echo "[SETUP] - See https://github.com/iden3/snarkjs for a list of ptau files."
    wget \
        https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_13.ptau \
        -O ./powers_of_tau/powersOfTau28_hez_final_13.ptau
else
    echo "[SETUP] - Powers of tau detected, skipping download"
fi

echo "[SETUP] - Compiling circuit"
circom -o ./poseidon/out --r1cs --wasm --sym ./poseidon/associate_data.circom

echo "[SETUP] - Setting up phase 2 ceremony"
snarkjs g16s \
    ./poseidon/out/associate_data.r1cs \
    ./powers_of_tau/powersOfTau28_hez_final_13.ptau \
    ./poseidon/out/associate_data_0000.zkey

echo "[SETUP] - Contributing to the ceremony"
snarkjs zkc \
    ./poseidon/out/associate_data_0000.zkey \
    ./poseidon/out/associate_data.zkey \
    -e='unique new york'

echo "[SETUP] - Exporting verification key to json"
snarkjs zkev \
    ./poseidon/out/associate_data.zkey \
    ./poseidon/out/associate_data_verifier.json