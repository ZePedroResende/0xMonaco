extern crate git2;
use git2::{Repository, Commit, ObjectType, Cred, FetchOptions};
use std::fs::{self, File};
use termion::input::TermRead;
use std::io::{Write, stdout, stdin};
use std::path::Path;
use rayon::prelude::*;

pub fn download_git_files() {
    // Specify the repository URL and directory path
    let repository_url = "git@github.com:ZePedroResende/williams.git";
    let directory_path = "src/cars";
    let directory_save = "../../src/cars/older_version";

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
         let ssh_key_password =   ssh_key_password.trim();
        Cred::ssh_key("git",Some(Path::new("/home/resende/.ssh/id_rsa.pub")), 
            Path::new("/home/resende/.ssh/id_rsa"),  Some(ssh_key_password))
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
    revwalk.set_sorting(git2::Sort::TIME);

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

fn download_directory(repo: &Repository, tree: &git2::Tree, commit: &Commit, _directory_path: &str, specific_directory: &str) {
    tree.iter().for_each(|entry| {
        let entry_path = entry.name().unwrap();
        let object = repo.find_object(entry.id(), Some(ObjectType::Blob)).unwrap();
        let blob = object.peel_to_blob().unwrap();
        let content = blob.content();
        write_file(entry_path, content, commit, specific_directory);
    });
}


fn write_file(path: &str, buffer: &[u8], commit: &Commit, specific_directory: &str) {
    let new_path = format!("{}-{}", path, commit.id());
    let full_path = format!("{}/{}", specific_directory, new_path);
    let path = Path::new(&full_path);
    if let Some(dir) = path.parent() {
        fs::create_dir_all(dir).unwrap();
    }
    let mut file = File::create(&full_path).unwrap();
    file.write_all(buffer).unwrap();
}
