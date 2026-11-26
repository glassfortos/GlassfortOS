// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <KQuickConfigModule>

#include "snapshotmodel.h"

// System Settings module "Restore Points" (D-45): the snapshot timeline of
// the root configuration. Listing and pinning go to snapper's D-Bus service
// (the wheel group may use it, glassfort-settings); restoring goes to
// glassfort-helper, which asks polkit (D-44).
class RestorePoints : public KQuickConfigModule
{
    Q_OBJECT
    Q_PROPERTY(SnapshotModel *snapshots READ snapshots CONSTANT)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(uint bootedSnapshot READ bootedSnapshot CONSTANT)
    Q_PROPERTY(bool restoring READ restoring NOTIFY restoringChanged)

public:
    RestorePoints(QObject *parent, const KPluginMetaData &data);

    SnapshotModel *snapshots() const { return m_model; }
    bool loading() const { return m_loading; }
    QString error() const { return m_error; }
    uint bootedSnapshot() const { return m_booted; }
    bool restoring() const { return m_restoring; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setPinned(uint number, bool pinned);
    Q_INVOKABLE void restore(uint number);
    Q_INVOKABLE void reboot();

Q_SIGNALS:
    void loadingChanged();
    void errorChanged();
    void restoringChanged();
    void restored(uint number);
    void restoreFailed(const QString &message);

private:
    void setError(const QString &error);

    SnapshotModel *m_model;
    bool m_loading = false;
    bool m_restoring = false;
    QString m_error;
    uint m_booted = 0;
};
