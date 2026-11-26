// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QMap>
#include <QString>
#include <QVector>

class QDBusArgument;

// One snapshot as snapper's D-Bus service reports it (ListSnapshots,
// signature "(uquxussa{ss})").
struct SnapperSnapshot {
    uint number = 0;
    ushort type = 0; // 0 single, 1 pre, 2 post
    uint preNumber = 0;
    qlonglong date = 0; // seconds since the epoch, -1 for the running system
    uint uid = 0;
    QString description;
    QString cleanup;
    QMap<QString, QString> userdata;
};
Q_DECLARE_METATYPE(SnapperSnapshot)

const QDBusArgument &operator>>(const QDBusArgument &arg, SnapperSnapshot &s);
QDBusArgument &operator<<(QDBusArgument &arg, const SnapperSnapshot &s);

// Snapshots of the root configuration, newest first, without snapshot 0
// (the running system).
class SnapshotModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Roles {
        NumberRole = Qt::UserRole + 1,
        KindRole, // "before", "after" or "single"
        DateRole,
        DayRole, // section key: yyyy-MM-dd
        TitleRole,
        DetailRole,
        PinnedRole,
        BootedRole,
    };
    Q_ENUM(Roles)

    explicit SnapshotModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setSnapshots(QVector<SnapperSnapshot> snapshots, uint booted);
    const SnapperSnapshot *find(uint number) const;

    // Human-readable title; for a post snapshot pass its pre snapshot.
    static QString title(const SnapperSnapshot &s, const SnapperSnapshot *pre = nullptr);
    // What a snapper description stands for, in words.
    static QString what(const QString &description);
    static bool isPinned(const SnapperSnapshot &s);
    // Snapshot number booted by a kernel command line, 0 for the normal system.
    static uint snapshotFromCmdline(const QString &cmdline);

private:
    QVector<SnapperSnapshot> m_snapshots;
    uint m_booted = 0;
};
