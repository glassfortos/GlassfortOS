// SPDX-License-Identifier: GPL-3.0-or-later
#include "restorepoints.h"

#include <KLocalizedString>
#include <KPluginFactory>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusMetaType>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QFile>

K_PLUGIN_CLASS_WITH_JSON(RestorePoints, "kcm_glassfort_timemachine.json")

namespace
{
const QString SnapperService = QStringLiteral("org.opensuse.Snapper");
const QString SnapperPath = QStringLiteral("/org/opensuse/Snapper");
const QString SnapperInterface = QStringLiteral("org.opensuse.Snapper");
const QString SnapperConfig = QStringLiteral("root");

const QString HelperService = QStringLiteral("org.glassfort.Helper1");
const QString HelperPath = QStringLiteral("/org/glassfort/Helper1");
const QString HelperInterface = QStringLiteral("org.glassfort.Helper1");
// The helper answers when the restore has finished; the password dialog
// comes first. Generous, the helper itself stops after 15 minutes.
constexpr int RestoreTimeoutMs = 20 * 60 * 1000;
}

RestorePoints::RestorePoints(QObject *parent, const KPluginMetaData &data)
    : KQuickConfigModule(parent, data)
    , m_model(new SnapshotModel(this))
{
    qDBusRegisterMetaType<SnapperSnapshot>();
    qDBusRegisterMetaType<QList<SnapperSnapshot>>();
    qDBusRegisterMetaType<QMap<QString, QString>>(); // userdata, a{ss}
    setButtons(NoAdditionalButton);

    QFile cmdline(QStringLiteral("/proc/cmdline"));
    if (cmdline.open(QIODevice::ReadOnly)) {
        m_booted = SnapshotModel::snapshotFromCmdline(QString::fromUtf8(cmdline.readAll()));
    }
    refresh();
}

void RestorePoints::setError(const QString &error)
{
    if (m_error != error) {
        m_error = error;
        Q_EMIT errorChanged();
    }
}

void RestorePoints::refresh()
{
    m_loading = true;
    Q_EMIT loadingChanged();
    auto msg = QDBusMessage::createMethodCall(SnapperService, SnapperPath, SnapperInterface, QStringLiteral("ListSnapshots"));
    msg << SnapperConfig;
    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::systemBus().asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *w) {
        w->deleteLater();
        QDBusPendingReply<QList<SnapperSnapshot>> reply = *w;
        m_loading = false;
        Q_EMIT loadingChanged();
        if (reply.isError()) {
            setError(i18n("The list of restore points could not be read: %1", reply.error().message()));
            return;
        }
        setError(QString());
        m_model->setSnapshots(reply.value().toVector(), m_booted);
    });
}

void RestorePoints::setPinned(uint number, bool pinned)
{
    const SnapperSnapshot *s = m_model->find(number);
    if (!s) {
        return;
    }
    QMap<QString, QString> userdata = s->userdata;
    if (pinned) {
        userdata.insert(QStringLiteral("important"), QStringLiteral("yes"));
    } else {
        userdata.remove(QStringLiteral("important"));
    }
    auto msg = QDBusMessage::createMethodCall(SnapperService, SnapperPath, SnapperInterface, QStringLiteral("SetSnapshot"));
    msg << SnapperConfig << number << s->description << s->cleanup << QVariant::fromValue(userdata);
    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::systemBus().asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *w) {
        w->deleteLater();
        QDBusPendingReply<> reply = *w;
        if (reply.isError()) {
            setError(i18n("The restore point could not be changed: %1", reply.error().message()));
        }
        refresh();
    });
}

void RestorePoints::restore(uint number)
{
    if (m_restoring || number == 0) {
        return;
    }
    m_restoring = true;
    Q_EMIT restoringChanged();
    auto msg = QDBusMessage::createMethodCall(HelperService, HelperPath, HelperInterface, QStringLiteral("RestoreSnapshot"));
    msg << number;
    msg.setInteractiveAuthorizationAllowed(true);
    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::systemBus().asyncCall(msg, RestoreTimeoutMs), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, number](QDBusPendingCallWatcher *w) {
        w->deleteLater();
        QDBusPendingReply<> reply = *w;
        m_restoring = false;
        Q_EMIT restoringChanged();
        if (reply.isError()) {
            const QString name = reply.error().name();
            if (name == QLatin1String("org.freedesktop.DBus.Error.AccessDenied")) {
                Q_EMIT restoreFailed(i18n("The restore was cancelled or not allowed."));
            } else {
                Q_EMIT restoreFailed(reply.error().message());
            }
            return;
        }
        Q_EMIT restored(number);
        refresh();
    });
}

void RestorePoints::reboot()
{
    // Plasma's own restart: asks running apps to save, then reboots.
    auto msg = QDBusMessage::createMethodCall(QStringLiteral("org.kde.Shutdown"),
                                              QStringLiteral("/Shutdown"),
                                              QStringLiteral("org.kde.Shutdown"),
                                              QStringLiteral("logoutAndReboot"));
    QDBusConnection::sessionBus().asyncCall(msg);
}

#include "restorepoints.moc"
