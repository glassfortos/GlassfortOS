// SPDX-License-Identifier: GPL-3.0-or-later
#include "snapshotmodel.h"

#include <KLocalizedString>
#include <QDBusArgument>
#include <QRegularExpression>
#include <algorithm>

const QDBusArgument &operator>>(const QDBusArgument &arg, SnapperSnapshot &s)
{
    arg.beginStructure();
    arg >> s.number >> s.type >> s.preNumber >> s.date >> s.uid >> s.description >> s.cleanup;
    s.userdata.clear();
    arg.beginMap();
    while (!arg.atEnd()) {
        QString key, value;
        arg.beginMapEntry();
        arg >> key >> value;
        arg.endMapEntry();
        s.userdata.insert(key, value);
    }
    arg.endMap();
    arg.endStructure();
    return arg;
}

QDBusArgument &operator<<(QDBusArgument &arg, const SnapperSnapshot &s)
{
    arg.beginStructure();
    arg << s.number << s.type << s.preNumber << s.date << s.uid << s.description << s.cleanup;
    arg.beginMap(QMetaType::fromType<QString>(), QMetaType::fromType<QString>());
    for (auto it = s.userdata.cbegin(); it != s.userdata.cend(); ++it) {
        arg.beginMapEntry();
        arg << it.key() << it.value();
        arg.endMapEntry();
    }
    arg.endMap();
    arg.endStructure();
    return arg;
}

SnapshotModel::SnapshotModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int SnapshotModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_snapshots.size();
}

bool SnapshotModel::isPinned(const SnapperSnapshot &s)
{
    return s.userdata.value(QStringLiteral("important")) == QLatin1String("yes");
}

uint SnapshotModel::snapshotFromCmdline(const QString &cmdline)
{
    // limine-snapper-sync boots snapshots with rootflags=subvol=/@snapshots/<n>/snapshot
    static const QRegularExpression re(QStringLiteral("(?:^|\\s)rootflags=\\S*subvol=/?@snapshots/(\\d+)/snapshot(?:[,\\s]|$)"));
    const auto m = re.match(cmdline);
    return m.hasMatch() ? m.captured(1).toUInt() : 0;
}

QString SnapshotModel::title(const SnapperSnapshot &s)
{
    // snap-pac describes its pre/post snapshots with the pacman command line,
    // e.g. "pacman -Syu" or "pacman -S --noconfirm firefox".
    QString what = s.description.trimmed();
    static const QRegularExpression pacman(QStringLiteral("^(?:/usr/bin/)?pacman\\s+(.*)$"));
    const auto m = pacman.match(what);
    if (m.hasMatch()) {
        const QStringList args = m.captured(1).split(QLatin1Char(' '), Qt::SkipEmptyParts);
        QStringList packages;
        QChar op;
        bool upgrade = false; // -Su / -Syu: system update
        for (const QString &a : args) {
            if (a.startsWith(QLatin1Char('-'))) {
                if (op.isNull() && a.size() > 1 && a[1] != QLatin1Char('-')) {
                    op = a[1];
                    upgrade = op == QLatin1Char('S') && a.mid(2).contains(QLatin1Char('u'));
                }
                continue;
            }
            packages << a;
        }
        const QString list = packages.size() > 3
            ? i18np("%2 and %1 more", "%2 and %1 more", packages.size() - 2, packages.mid(0, 2).join(QStringLiteral(", ")))
            : packages.join(QStringLiteral(", "));
        if (upgrade) {
            what = packages.isEmpty() ? i18n("System update") : i18n("System update and installing %1", list);
        } else if ((op == QLatin1Char('S') || op == QLatin1Char('U')) && !packages.isEmpty()) {
            what = i18n("Installing %1", list);
        } else if (op == QLatin1Char('R') && !packages.isEmpty()) {
            what = i18n("Removing %1", list);
        } else {
            what = i18n("Package change");
        }
    } else if (what.isEmpty()) {
        what = i18n("Snapshot");
    }

    switch (s.type) {
    case 1:
        return i18nc("snapshot taken before a change", "Before: %1", what);
    case 2:
        return i18nc("snapshot taken after a change", "After: %1", what);
    default:
        return what;
    }
}

QVariant SnapshotModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_snapshots.size()) {
        return {};
    }
    const SnapperSnapshot &s = m_snapshots.at(index.row());
    const QDateTime date = QDateTime::fromSecsSinceEpoch(s.date);
    switch (role) {
    case Qt::DisplayRole:
    case TitleRole:
        return title(s);
    case NumberRole:
        return s.number;
    case KindRole:
        return s.type == 1 ? QStringLiteral("before") : s.type == 2 ? QStringLiteral("after") : QStringLiteral("single");
    case DateRole:
        return date;
    case DayRole:
        return date.date().toString(Qt::ISODate);
    case DetailRole:
        return s.description;
    case PinnedRole:
        return isPinned(s);
    case BootedRole:
        return m_booted != 0 && s.number == m_booted;
    }
    return {};
}

QHash<int, QByteArray> SnapshotModel::roleNames() const
{
    return {
        {NumberRole, "number"},
        {KindRole, "kind"},
        {DateRole, "date"},
        {DayRole, "day"},
        {TitleRole, "title"},
        {DetailRole, "detail"},
        {PinnedRole, "pinned"},
        {BootedRole, "booted"},
    };
}

void SnapshotModel::setSnapshots(QVector<SnapperSnapshot> snapshots, uint booted)
{
    snapshots.erase(std::remove_if(snapshots.begin(),
                                   snapshots.end(),
                                   [](const SnapperSnapshot &s) {
                                       return s.number == 0;
                                   }),
                    snapshots.end());
    std::sort(snapshots.begin(), snapshots.end(), [](const SnapperSnapshot &a, const SnapperSnapshot &b) {
        return a.date != b.date ? a.date > b.date : a.number > b.number;
    });
    beginResetModel();
    m_snapshots = std::move(snapshots);
    m_booted = booted;
    endResetModel();
}

const SnapperSnapshot *SnapshotModel::find(uint number) const
{
    for (const auto &s : m_snapshots) {
        if (s.number == number) {
            return &s;
        }
    }
    return nullptr;
}
