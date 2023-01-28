//#![cfg(test)]
#![allow(unused_parens)]

mod forge;

use crate::forge::{execute, runner, print_contract_files_and_names};
use ethers::types::U256;

use rayon::prelude::*;
use rayon::iter::ParallelIterator;
use rayon::iter::ParallelBridge;
use itertools::Itertools;

type Out = (U256,String, U256,String, U256,String );
pub fn run_simulation() {
    let contracts: Vec<String> = print_contract_files_and_names();


    println!("{:?}", contracts);
    let permutation  = contracts.into_iter().permutations(3).unique();

    permutation.par_bridge().for_each(move |v| {
        run_test(&v);
    });

}

fn run_test(v: &[String]){

    let mut runner = runner();

    let calculated = execute::<_, Out>(
        &mut runner,
        "SimulateTest",
        "testSimulationByName",
        (v[0].to_owned(),v[1].to_owned(),v[2].to_owned()), 
    );

        println!("{},{},{};{:?}", v[0], v[1],v[2],calculated);
}


