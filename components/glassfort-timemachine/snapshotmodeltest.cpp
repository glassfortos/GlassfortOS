// SPDX-License-Identifier: GPL-3.0-or-later
#include "snapshotmodel.h"

#include <QTest>

class SnapshotModelTest : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void titles_data()
    {
        QTest::addColumn<ushort>("type");
        QTest::addColumn<QString>("description");
        QTest::addColumn<QString>("title");
        QTest::newRow("update") << ushort(1) << "pacman -Syu" << "Before: System update";
        QTest::newRow("update+install") << ushort(2) << "pacman -Syu firefox" << "After: System update and installing firefox";
        QTest::newRow("install") << ushort(1) << "pacman -S --noconfirm --needed cowsay" << "Before: Installing cowsay";
        QTest::newRow("remove") << ushort(1) << "pacman -Rdd --noconfirm systemd" << "Before: Removing systemd";
        QTest::newRow("local file") << ushort(1) << "pacman -U /tmp/x.pkg.tar.zst" << "Before: Installing /tmp/x.pkg.tar.zst";
        QTest::newRow("many") << ushort(1) << "pacman -S a b c d e" << "Before: Installing a, b and 3 more";
        QTest::newRow("other op") << ushort(1) << "pacman -D --asdeps foo" << "Before: Package change";
        QTest::newRow("single") << ushort(0) << "boot" << "boot";
        QTest::newRow("empty") << ushort(0) << "" << "Snapshot";
    }

    void titles()
    {
        QFETCH(ushort, type);
        QFETCH(QString, description);
        QFETCH(QString, title);
        SnapperSnapshot s;
        s.type = type;
        s.description = description;
        QCOMPARE(SnapshotModel::title(s), title);
    }

    void cmdline_data()
    {
        QTest::addColumn<QString>("cmdline");
        QTest::addColumn<uint>("number");
        QTest::newRow("normal") << "root=/dev/mapper/root rootflags=subvol=@ rw quiet" << 0u;
        QTest::newRow("snapshot") << "cryptdevice=PARTUUID=x:root root=/dev/mapper/root rootflags=subvol=/@snapshots/5/snapshot rw" << 5u;
        QTest::newRow("no slash") << "rootflags=subvol=@snapshots/12/snapshot" << 12u;
        QTest::newRow("more flags") << "rootflags=compress=zstd,subvol=/@snapshots/7/snapshot,noatime quiet" << 7u;
        QTest::newRow("not rootflags") << "foo=subvol=/@snapshots/7/snapshot" << 0u;
        QTest::newRow("prefix") << "xrootflags=subvol=/@snapshots/7/snapshot" << 0u;
    }

    void cmdline()
    {
        QFETCH(QString, cmdline);
        QFETCH(uint, number);
        QCOMPARE(SnapshotModel::snapshotFromCmdline(cmdline), number);
    }

    void modelSortsAndDropsRunningSystem()
    {
        SnapshotModel model;
        SnapperSnapshot running, older, newer;
        running.number = 0;
        older.number = 3;
        older.date = 100;
        newer.number = 4;
        newer.date = 200;
        newer.userdata.insert(QStringLiteral("important"), QStringLiteral("yes"));
        model.setSnapshots({running, older, newer}, 3);
        QCOMPARE(model.rowCount(), 2);
        QCOMPARE(model.data(model.index(0), SnapshotModel::NumberRole).toUInt(), 4u);
        QCOMPARE(model.data(model.index(0), SnapshotModel::PinnedRole).toBool(), true);
        QCOMPARE(model.data(model.index(1), SnapshotModel::BootedRole).toBool(), true);
        QCOMPARE(model.data(model.index(0), SnapshotModel::BootedRole).toBool(), false);
    }
};

QTEST_GUILESS_MAIN(SnapshotModelTest)
#include "snapshotmodeltest.moc"
