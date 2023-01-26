mod git;


use git::download_git_files;

fn main() {
    download_git_files();
    simulator::run_simulation();
}
