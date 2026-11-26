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
        QTest::newRow("update+install") << ushort(1) << "pacman -Syu firefox" << "Before: System update and installing firefox";
        QTest::newRow("install") << ushort(1) << "pacman -S --noconfirm --needed cowsay" << "Before: Installing cowsay";
        QTest::newRow("remove") << ushort(1) << "pacman -Rdd --noconfirm systemd" << "Before: Removing systemd";
        QTest::newRow("local file") << ushort(1) << "pacman -U /tmp/x.pkg.tar.zst" << "Before: Installing /tmp/x.pkg.tar.zst";
        QTest::newRow("many") << ushort(1) << "pacman -S a b c d e" << "Before: Installing a, b and 3 more";
        QTest::newRow("other op") << ushort(1) << "pacman -D --asdeps foo" << "Before: Package change";
        QTest::newRow("post alone") << ushort(2) << "cowsay" << "After: Software change: cowsay";
        QTest::newRow("package list") << ushort(0) << "a52dec accountsservice adw-gtk-theme qt6-base" << "Software change: a52dec, accountsservice and 2 more";
        QTest::newRow("backup") << ushort(0) << "backup before restore #4" << "Backup before a restore";
        QTest::newRow("free text") << ushort(0) << "Before the big change!" << "Before the big change!";
        QTest::newRow("empty") << ushort(0) << "" << "Restore point";
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

    void postTakesTitleFromPre()
    {
        SnapperSnapshot pre, post;
        pre.number = 4;
        pre.type = 1;
        pre.description = QStringLiteral("pacman -Rdd --noconfirm systemd");
        post.number = 5;
        post.type = 2;
        post.preNumber = 4;
        post.description = QStringLiteral("systemd");
        QCOMPARE(SnapshotModel::title(post, &pre), QStringLiteral("After: Removing systemd"));
        SnapshotModel model;
        model.setSnapshots({pre, post}, 0);
        QCOMPARE(model.data(model.index(0), SnapshotModel::TitleRole).toString(), QStringLiteral("After: Removing systemd"));
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
