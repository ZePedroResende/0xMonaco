//taken from https://github.com/polytope-labs/solidity-merkle-trees/blob/main/tests/src/forge.rs
use ethers::{
    abi::{Detokenize, Tokenize},
    solc::utils::source_files,
    solc::utils::source_name,
    solc::{Project, ProjectCompileOutput, ProjectPathsConfig},
    types::U256,
};
use forge::{
    executor::{
        inspector::CheatsConfig,
        opts::{Env, EvmOpts},
    },
    result::TestSetup,
    ContractRunner, MultiContractRunner, MultiContractRunnerBuilder,
};
use foundry_config::{fs_permissions::PathPermission, Config, FsPermissions};
use foundry_evm::executor::{Backend, ExecutorBuilder};
use once_cell::sync::Lazy;
use std::{
    fmt::Debug,
    path::{Path, PathBuf},
};

static PROJECT: Lazy<Project> = Lazy::new(|| {
    let mut root = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    root = PathBuf::from(root.parent().unwrap().clone());
    let paths = ProjectPathsConfig::builder()
        .root(root.clone())
        .sources(root)
        .build()
        .unwrap();
    Project::builder()
        .paths(paths)
        .ephemeral()
        .no_artifacts()
        .build()
        .unwrap()
});

static EVM_OPTS: Lazy<EvmOpts> = Lazy::new(|| EvmOpts {
    env: Env {
        gas_limit: 18446744073709551615,
        chain_id: Some(foundry_common::DEV_CHAIN_ID),
        tx_origin: Config::DEFAULT_SENDER,
        block_number: 1,
        block_timestamp: 1,
        ..Default::default()
    },
    sender: Config::DEFAULT_SENDER,
    initial_balance: U256::MAX,
    ffi: true,
    memory_limit: 2u64.pow(24),
    ..Default::default()
});

static COMPILED: Lazy<ProjectCompileOutput> = Lazy::new(|| {
    let out = (*PROJECT).compile().unwrap();
    if out.has_compiler_errors() {
        eprintln!("{out}");
        panic!("Compiled with errors");
    }
    out
});

/// Builds a base runner
fn base_runner() -> MultiContractRunnerBuilder {
    MultiContractRunnerBuilder::default().sender(EVM_OPTS.sender)
}

fn manifest_root() -> PathBuf {
    let mut root = Path::new(env!("CARGO_MANIFEST_DIR"));
    // need to check here where we're executing the test from, if in `forge` we need to also allow
    // `testdata`
    if root.ends_with("test") {
        root = root.parent().unwrap();
    }
    root.to_path_buf()
}

/// Builds a non-tracing runner
fn runner_with_config(mut config: Config) -> MultiContractRunner {
    config.allow_paths.push(manifest_root());

    base_runner()
        .with_cheats_config(CheatsConfig::new(&config, &EVM_OPTS))
        .sender(config.sender)
        .build(
            &PROJECT.paths.root,
            (*COMPILED).clone(),
            EVM_OPTS.evm_env_blocking().unwrap(),
            EVM_OPTS.clone(),
        )
        .unwrap()
}

/// Builds a non-tracing runner
pub fn runner() -> MultiContractRunner {
    let mut config = Config::with_root(PROJECT.root());
    config.fs_permissions = FsPermissions::new(vec![
        PathPermission::read_write(manifest_root()),
        PathPermission::read_write(PathBuf::from("simulations")),
        PathPermission::read_write(PathBuf::from("out")),
    ]);
    runner_with_config(config)
}

pub fn execute<T, R>(
    runner: &mut MultiContractRunner,
    contract_name: &'static str,
    fn_name: &'static str,
    args: T,
) -> R
where
    T: Tokenize + Debug,
    R: Detokenize + Debug,
{
    let db = Backend::spawn(runner.fork.take());

    let (_, (abi, deploy_code, libs)) = runner
        .contracts
        .iter()
        .find(|(id, (abi, _, _))| id.name == contract_name && abi.functions.contains_key(fn_name))
        .unwrap();

    let function = abi.functions.get(fn_name).unwrap().first().unwrap().clone();

    let executor = ExecutorBuilder::default()
        .with_cheatcodes(runner.cheats_config.clone())
        .with_config(runner.env.clone())
        .with_spec(runner.evm_spec)
        .with_gas_limit(runner.evm_opts.gas_limit())
        .set_tracing(runner.evm_opts.verbosity >= 3)
        .set_coverage(runner.coverage)
        .build(db);

    let mut single_runner = ContractRunner::new(
        executor,
        abi,
        deploy_code.clone(),
        runner.evm_opts.initial_balance,
        runner.sender,
        runner.errors.as_ref(),
        libs,
    );

    let setup = single_runner.setup(false).unwrap();
    let TestSetup { address, .. } = setup;

    let error_string = format!("crashed overflow : {:?}", args);

    let result = single_runner
        .executor
        .execute_test::<R, _, _>(
            single_runner.sender,
            address,
            function,
            args,
            0.into(),
            single_runner.errors,
        )
        .expect(&error_string);

    result.result
}

pub fn print_contract_files_and_names() -> Vec<String> {
    let out = (*COMPILED)
        .clone()
        .output()
        .with_stripped_file_prefixes(PROJECT.root());

    let sources: Vec<(String)> = out
        .contracts_with_files_iter()
        .filter(|(a, _, _)| a.contains("src/cars/"))
        .filter(|(a, _, _)| !a.contains("src/cars/samples"))
        .filter(|(a, _, _)| !a.contains("Base"))
        .filter(|(a, _, _)| !a.contains("src/cars/Example"))
        .map(|(a, b, _)| {
            let a = if a.contains("older_version") {
                a.strip_prefix("src/cars/older_version/").unwrap_or(a)
            } else if a.contains("samples") {
                a.strip_prefix("src/cars/samples/").unwrap_or(a)
            } else if a.contains("src/cars/bradbury") {
                a.strip_prefix("src/cars/bradbury/").unwrap_or(a)
            } else if a.contains("src/cars/fardalheira/") {
                a.strip_prefix("src/cars/fardalheira/").unwrap_or(a)
            } else if a.contains("src/cars/Season I finalists/") {
                a.strip_prefix("src/cars/Season I finalists/").unwrap_or(a)
            } else {
                a.strip_prefix("src/cars/").unwrap_or(a)
            };
            format!("{a}:{b}")
        })
        .collect();

    dbg!(&sources);

    sources
}
