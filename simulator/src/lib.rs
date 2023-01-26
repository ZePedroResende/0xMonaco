//#![cfg(test)]
#![allow(unused_parens)]

mod forge;

use crate::forge::{execute, runner};
use ethers::{abi::Token, types::U256, utils::keccak256};
use hex_literal::hex;

pub fn run_simulation() {
//    .iter()
//    .map(|h| keccak256(&h))
//    .collect::<Vec<[u8; 32]>>();
//
//    let tree = MerkleTree::<Keccak256>::from_leaves(&leaf_hashes);
//
//    let leaves = vec![0, 2, 5, 9, 20, 25, 31];
//    let leaves_with_indices = leaves
//        .iter()
//        .map(|i| {
//            Token::Tuple(vec![
//                Token::Uint(U256::from(*i)),
//                Token::FixedBytes(leaf_hashes[*i].to_vec()),
//            ])
//        })
//        .collect::<Vec<_>>();
//
//    let proof = tree.proof_2d(&leaves);
//
//    let args = proof
//        .into_iter()
//        .map(|layers| {
//            let layers = layers
//                .into_iter()
//                .map(|(index, node)| {
//                    Token::Tuple(vec![
//                        Token::Uint(U256::from(index)),
//                        Token::FixedBytes(node.to_vec()),
//                    ])
//                })
//                .collect::<Vec<_>>();
//            Token::Array(layers)
//        })
//        .collect::<Vec<_>>();
type Out = (U256,String, U256,String, U256,String );


    let mut runner = runner();

    let calculated = execute::<_, Out>(
        &mut runner,
        "SimulateTest",
        "testSimulationByName",
//        (),
        ("B_biggerAccelFloor.sol:BradburyBigAccelFloor".to_string(),"B_biggerEndBudget.sol:BradburyBiggerEndBudget".to_string(),"B_goBananas.sol:BradburyGoBananas".to_string()), 
    );

    println!("{:?}", calculated);
}
