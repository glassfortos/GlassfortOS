// SPDX-License-Identifier: GPL-3.0-or-later
//! Restoring a snapshot with limine-snapper-sync (D-44).
//!
//! The restore itself is limine-snapper-sync's: it swaps the root subvolume
//! for a writable copy of the snapshot, keeps a backup snapshot of the
//! current state and rewrites the boot menu. Glassfort's patch adds
//! `--non-interactive`, so it never waits for a terminal and never reboots
//! on its own; the Time Machine asks the user about the restart.

use std::process::Stdio;
use std::time::Duration;

use tokio::process::Command;

const LIMINE_SNAPPER_SYNC: &str = "/usr/bin/limine-snapper-sync";
/// A restore copies the boot files and the root subvolume metadata; it
/// normally takes seconds. Anything near this limit is stuck.
const TIMEOUT: Duration = Duration::from_secs(15 * 60);
/// Snapper numbers snapshots from 1; 0 is the running system.
const MAX_ID: u32 = 999_999_999;

/// Reject ids that cannot be snapshots. Whether the snapshot exists and its
/// boot files are intact is checked by limine-snapper-sync itself.
pub fn validate_id(id: u32) -> Result<(), String> {
    if id == 0 {
        return Err("snapshot 0 is the running system".into());
    }
    if id > MAX_ID {
        return Err(format!("snapshot id {id} is out of range"));
    }
    Ok(())
}

/// Command line for restoring snapshot `id`; no shell is involved.
pub fn command_line(id: u32) -> Vec<String> {
    vec![
        LIMINE_SNAPPER_SYNC.to_string(),
        "--restore".to_string(),
        id.to_string(),
        "--non-interactive".to_string(),
    ]
}

/// Last lines of the tool's output, for the error message the user sees.
pub fn tail(output: &str, lines: usize) -> String {
    let all: Vec<&str> = output.lines().filter(|l| !l.trim().is_empty()).collect();
    all[all.len().saturating_sub(lines)..].join("\n")
}

pub async fn run(id: u32) -> Result<(), String> {
    validate_id(id)?;
    let argv = command_line(id);
    let child = Command::new(&argv[0])
        .args(&argv[1..])
        .env_clear()
        .env("PATH", "/usr/local/sbin:/usr/local/bin:/usr/bin")
        .env("LANG", "C.UTF-8")
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .kill_on_drop(true)
        .spawn()
        .map_err(|e| format!("cannot start limine-snapper-sync: {e}"))?;
    let output = match tokio::time::timeout(TIMEOUT, child.wait_with_output()).await {
        Ok(result) => result.map_err(|e| format!("limine-snapper-sync failed: {e}"))?,
        Err(_) => return Err("the restore did not finish in time".into()),
    };
    let text = format!(
        "{}{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    for line in text.lines() {
        eprintln!("limine-snapper-sync: {line}");
    }
    match output.status.code() {
        Some(0) => Ok(()),
        Some(3) => Err(format!(
            "The snapshot was restored, but a boot hook failed:\n{}",
            tail(&text, 5)
        )),
        _ => Err(format!(
            "The snapshot could not be restored:\n{}",
            tail(&text, 5)
        )),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_running_system_and_huge_ids() {
        assert!(validate_id(0).is_err());
        assert!(validate_id(MAX_ID + 1).is_err());
        assert!(validate_id(u32::MAX).is_err());
        assert!(validate_id(1).is_ok());
        assert!(validate_id(MAX_ID).is_ok());
    }

    #[test]
    fn command_line_is_fixed_and_shell_free() {
        assert_eq!(
            command_line(42),
            [
                "/usr/bin/limine-snapper-sync",
                "--restore",
                "42",
                "--non-interactive"
            ]
        );
    }

    #[test]
    fn tail_keeps_last_non_empty_lines() {
        assert_eq!(tail("a\n\nb\nc\n\n", 2), "b\nc");
        assert_eq!(tail("only", 5), "only");
        assert_eq!(tail("", 3), "");
    }
}
