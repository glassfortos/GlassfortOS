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

namespace
{
QString packageList(const QStringList &packages)
{
    return packages.size() > 3 ? i18np("%2 and %1 more", "%2 and %1 more", packages.size() - 2, packages.mid(0, 2).join(QStringLiteral(", ")))
                               : packages.join(QStringLiteral(", "));
}
}

QString SnapshotModel::what(const QString &description)
{
    const QString text = description.trimmed();
    // snap-pac describes pre snapshots with the pacman command line, e.g.
    // "pacman -Syu" or "pacman -S --noconfirm firefox" ...
    static const QRegularExpression pacman(QStringLiteral("^(?:/usr/bin/)?pacman\\s+(.*)$"));
    const auto m = pacman.match(text);
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
        if (upgrade) {
            return packages.isEmpty() ? i18n("System update") : i18n("System update and installing %1", packageList(packages));
        }
        if ((op == QLatin1Char('S') || op == QLatin1Char('U')) && !packages.isEmpty()) {
            return i18n("Installing %1", packageList(packages));
        }
        if (op == QLatin1Char('R') && !packages.isEmpty()) {
            return i18n("Removing %1", packageList(packages));
        }
        return i18n("Package change");
    }
    // ... limine-snapper-sync names the copy of the state it replaces ...
    static const QRegularExpression backup(QStringLiteral("^backup before restore #\\d+$"));
    if (backup.match(text).hasMatch()) {
        return i18n("Backup before a restore");
    }
    // ... and snap-pac's post snapshots list the changed packages.
    static const QRegularExpression packageNames(QStringLiteral("^[a-z0-9@._+-]+(?: [a-z0-9@._+-]+)*$"));
    if (packageNames.match(text).hasMatch()) {
        return i18n("Software change: %1", packageList(text.split(QLatin1Char(' '))));
    }
    return text.isEmpty() ? i18n("Restore point") : text;
}

QString SnapshotModel::title(const SnapperSnapshot &s, const SnapperSnapshot *pre)
{
    switch (s.type) {
    case 1:
        return i18nc("snapshot taken before a change", "Before: %1", what(s.description));
    case 2:
        // The post snapshot only lists package names; its pre snapshot
        // knows what was done.
        return i18nc("snapshot taken after a change", "After: %1", what(pre ? pre->description : s.description));
    default:
        return what(s.description);
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
        return title(s, s.type == 2 ? find(s.preNumber) : nullptr);
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
