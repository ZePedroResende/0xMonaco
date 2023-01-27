extern crate git2;
use git2::{Commit, Cred, FetchOptions, ObjectType, Repository};
use rayon::prelude::*;
use regex::bytes::Captures;
use regex::bytes::Regex as Regexb;
use regex::Regex;
use std::fs::{self, File};
use std::io::{stdin, stdout, Write};
use std::path::Path;
use termion::input::TermRead;

pub fn download_git_files() {
    // Specify the repository URL and directory path
    let repository_url = "git@github.com:ZePedroResende/williams.git";
    let directory_path = "src/cars";
    let directory_save = "../src/cars/older_version";

    // Open the repository with ssh key
    let mut builder = git2::build::RepoBuilder::new();
    let mut callbacks = git2::RemoteCallbacks::new();
    let mut fetch_options = FetchOptions::new();

    callbacks.credentials(|_, _, _| {
        let stdout = stdout();
        let mut stdout = stdout.lock();
        let stdin = stdin();
        let mut stdin = stdin.lock();

        stdout.write_all(b"password: ").unwrap();
        stdout.flush().unwrap();

        let ssh_key_password = stdin.read_passwd(&mut stdout).expect("Not valid password");
        let ssh_key_password = ssh_key_password.expect("invalid password");
        let ssh_key_password = ssh_key_password.trim();
        //Cred::ssh_key("git",Some(Path::new("/home/resende/.ssh/id_ed25519.pub")),
        //    Path::new("/home/resende/.ssh/id_ed25519"),  Some(ssh_key_password))
        Cred::ssh_key(
            "git",
            Some(Path::new("/home/resende/.ssh/id_rsa.pub")),
            Path::new("/home/resende/.ssh/id_rsa"),
            Some(ssh_key_password),
        )
    });

    fetch_options.remote_callbacks(callbacks);

    builder.fetch_options(fetch_options);

    let repo = match builder.clone(&repository_url, Path::new("/tmp/williams")) {
        Ok(repo) => repo,
        Err(e) => panic!("failed to open: {}", e),
    };

    // Get the head commit
    let head = match repo.head() {
        Ok(head) => head,
        Err(e) => panic!("failed to get head: {}", e),
    };

    // Walk through the commit history
    let mut revwalk = repo.revwalk().unwrap();
    revwalk.push(head.target().unwrap()).unwrap();
    revwalk.set_sorting(git2::Sort::TIME).unwrap();

    for id in revwalk {
        let commit = match repo.find_commit(id.unwrap()) {
            Ok(commit) => commit,
            Err(e) => panic!("failed to find commit: {}", e),
        };

        // Get the directory's tree
        let tree = commit.tree().unwrap();
        let entry = tree.get_path(Path::new(directory_path)).unwrap();
        let tree = match repo.find_tree(entry.id()) {
            Ok(tree) => tree,
            Err(e) => panic!("failed to find tree: {}", e),
        };
        // Recursive function to download the directory
        download_directory(&repo, &tree, &commit, &directory_path, &directory_save);
    }
}

fn download_directory(
    repo: &Repository,
    tree: &git2::Tree,
    commit: &Commit,
    _directory_path: &str,
    specific_directory: &str,
) {
    tree.iter().for_each(|entry| {
        let entry_path = entry.name().unwrap();
        let object = repo.find_object(entry.id(), None).unwrap();

        if object.kind() == Some(ObjectType::Blob) {
            let blob = object.peel_to_blob().unwrap();
            let content = blob.content();
            write_file(entry_path, content, commit, specific_directory);
        }
    });
}

fn write_file(path: &str, buffer: &[u8], commit: &Commit, specific_directory: &str) {
    let black_list = vec![
        "Bradbury-b99f98cb6d63e4f4a7874ad9914fdfc74ed42c53",
        "Bradbury-e8b021f3a859632d57fe4a6628789862f86e8c2f",
    ];

    let re = Regex::new(r"(.*)?.sol$").unwrap();
    let captures = re
        .captures(path)
        .expect("failed to capture file name from solidity");

    let file_name = captures.get(1).expect("failed to match file").as_str();
    let new_name = format!("{}-{}", file_name, commit.id());
    if black_list.contains(&&new_name.as_str()) {
        return;
    }
    let new_path = format!("{}.sol", new_name);

    let full_path = format!("{}/{}", specific_directory, new_path);

    let path = Path::new(&full_path);
    println!("{:?}", path);
    if let Some(dir) = path.parent() {
        fs::create_dir_all(dir).unwrap();
    }
    let mut file = File::create(&full_path).unwrap();

    let re_contract_name = Regexb::new(r"\s*contract\s*(\w*)\s*(.*)?\{").unwrap();
    let replaced_buffer = re_contract_name.replace(&buffer, |caps: &Captures| {
        let mut new_contract_name: Vec<u8> = b"\ncontract ".to_vec();
        new_contract_name.extend(&caps[1]);
        new_contract_name.push(b' ');
        new_contract_name.extend(&caps[2]);
        new_contract_name.push(b' ');
        new_contract_name.push(b'{');
        new_contract_name
    });

    let re_contract_name = Regexb::new(r"\./\.\./interfaces/ICar.sol").unwrap();
    let replaced_buffer =
        re_contract_name.replace(&replaced_buffer, &b"./../../interfaces/ICar.sol"[..]);

    file.write_all(&replaced_buffer).unwrap();
}
