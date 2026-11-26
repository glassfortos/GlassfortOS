// SPDX-License-Identifier: GPL-3.0-or-later
//! glassfort-helper: Glassfort's privileged D-Bus service (docs/02, docs/05, D-44).
//!
//! It runs as root, owns `org.glassfort.Helper1` on the system bus and offers
//! a small set of typed actions. Every action is checked with polkit for the
//! calling bus name before anything runs; every request and its outcome go to
//! the journal (stderr of the systemd unit). Phase 2 has one action:
//! restoring a snapshot for the Time Machine.

mod restore;

use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;

use tokio::sync::Mutex;
use zbus::message::Header;
use zbus::Variant;
use zbus::{fdo, interface, Connection};

const BUS_NAME: &str = "org.glassfort.Helper1";
const OBJECT_PATH: &str = "/org/glassfort/Helper1";
const ACTION_RESTORE: &str = "org.glassfort.helper.restore-snapshot";
/// Exit after this long without a request; D-Bus activation starts the
/// service again when needed.
const IDLE_EXIT: Duration = Duration::from_secs(300);

struct Helper {
    /// Held while an action runs: one system change at a time.
    busy: Arc<Mutex<()>>,
    activity: Arc<tokio::sync::Notify>,
}

/// Ask polkit whether the sender of the current message may run `action`.
/// AllowUserInteraction: polkit shows the password dialog of the caller's
/// session if the action needs it.
async fn authorize(conn: &Connection, sender: &str, action: &str) -> fdo::Result<()> {
    let mut subject_details: HashMap<&str, Variant<'_>> = HashMap::new();
    subject_details.insert("name", Variant::from(sender));
    let subject = ("system-bus-name", subject_details);
    let details: HashMap<&str, &str> = HashMap::new();
    let flags: u32 = 1; // AllowUserInteraction
    let reply = conn
        .call_method(
            Some("org.freedesktop.PolicyKit1"),
            "/org/freedesktop/PolicyKit1/Authority",
            Some("org.freedesktop.PolicyKit1.Authority"),
            "CheckAuthorization",
            &(subject, action, details, flags, ""),
        )
        .await
        .map_err(|e| fdo::Error::Failed(format!("polkit is not available: {e}")))?;
    let (authorized, _challenge, _details): (bool, bool, HashMap<String, String>) = reply
        .body()
        .deserialize()
        .map_err(|e| fdo::Error::Failed(format!("unexpected polkit reply: {e}")))?;
    if authorized {
        Ok(())
    } else {
        Err(fdo::Error::AccessDenied("Not authorized".into()))
    }
}

/// Unix user id of a bus name, for the audit log.
async fn caller_uid(conn: &Connection, sender: &str) -> Option<u32> {
    let dbus = fdo::DBusProxy::new(conn).await.ok()?;
    let name = zbus::names::BusName::try_from(sender).ok()?;
    dbus.get_connection_unix_user(name).await.ok()
}

#[interface(name = "org.glassfort.Helper1")]
impl Helper {
    /// Make snapshot `id` of the root configuration the running system
    /// again (takes effect after a restart). Returns when the restore has
    /// finished; callers should use a long method call timeout.
    async fn restore_snapshot(
        &self,
        #[zbus(header)] header: Header<'_>,
        #[zbus(connection)] conn: &Connection,
        id: u32,
    ) -> fdo::Result<()> {
        self.activity.notify_one();
        let sender = header
            .sender()
            .map(|s| s.to_string())
            .ok_or_else(|| fdo::Error::AccessDenied("No sender".into()))?;
        let uid = caller_uid(conn, &sender).await;
        let who = uid.map_or_else(|| sender.clone(), |u| format!("uid {u}"));

        restore::validate_id(id).map_err(|e| {
            eprintln!("audit: restore-snapshot {id} by {who}: rejected ({e})");
            fdo::Error::InvalidArgs(e)
        })?;
        if let Err(e) = authorize(conn, &sender, ACTION_RESTORE).await {
            eprintln!("audit: restore-snapshot {id} by {who}: not authorized");
            return Err(e);
        }
        let Ok(_guard) = self.busy.try_lock() else {
            eprintln!("audit: restore-snapshot {id} by {who}: refused, another action is running");
            return Err(fdo::Error::Failed(
                "Another system change is running".into(),
            ));
        };

        eprintln!("audit: restore-snapshot {id} by {who}: started");
        let result = restore::run(id).await;
        match &result {
            Ok(()) => eprintln!("audit: restore-snapshot {id} by {who}: done"),
            Err(e) => eprintln!("audit: restore-snapshot {id} by {who}: failed: {e}"),
        }
        self.activity.notify_one();
        result.map_err(fdo::Error::Failed)
    }

    /// Interface version, so clients can check what the helper offers.
    #[zbus(property)]
    fn version(&self) -> &str {
        env!("CARGO_PKG_VERSION")
    }
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> zbus::Result<()> {
    let activity = Arc::new(tokio::sync::Notify::new());
    let busy = Arc::new(Mutex::new(()));
    let helper = Helper {
        busy: busy.clone(),
        activity: activity.clone(),
    };
    let _conn = zbus::connection::Builder::system()
        .name(BUS_NAME)
        .serve_at(OBJECT_PATH, helper)
        .build()
        .await?;
    eprintln!("glassfort-helper {} ready", env!("CARGO_PKG_VERSION"));

    let mut term = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
        .map_err(|e| zbus::Error::Failure(e.to_string()))?;
    loop {
        tokio::select! {
            _ = activity.notified() => continue,
            _ = term.recv() => break,
            _ = tokio::time::sleep(IDLE_EXIT) => {
                // Never exit in the middle of an action.
                if busy.try_lock().is_ok() {
                    break;
                }
            }
        }
    }
    // Wait for a running action before leaving on SIGTERM as well.
    let _guard = busy.lock().await;
    Ok(())
}
