// wallpaper-picker — a standalone, compositor-portable wallpaper carousel.
//
// It uses wlr-layer-shell through LayerShellQt, so the same binary works on
// niri, Hyprland, Sway, Mango and other wlroots-based compositors. The UI is
// painted with QPainter; no compositor-specific QML or widget toolkit is
// required.

#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QHash>
#include <QImage>
#include <QImageReader>
#include <QJsonDocument>
#include <QJsonObject>
#include <QKeyEvent>
#include <QLocalServer>
#include <QLocalSocket>
#include <QMouseEvent>
#include <QPainter>
#include <QProcess>
#include <QRandomGenerator>
#include <QResizeEvent>
#include <QScreen>
#include <QSet>
#include <QStandardPaths>
#include <QTimer>
#include <QVariantAnimation>
#include <QWidget>
#include <QWheelEvent>
#include <QtConcurrent>

#include <LayerShellQt/window.h>

#include <algorithm>
#include <cmath>
#include <cstdio>

namespace {

constexpr int kVisibleSide = 3;
constexpr qreal kSideHeight = 0.92;
constexpr qreal kSideWidth = 0.20;
constexpr qreal kSideShrink = 0.78;
constexpr qreal kSideSlant = 0.10;
constexpr int kGap = 10;
constexpr int kAnimationMs = 280;

const QColor kAccent(0xe8, 0xb6, 0x4b);
const QColor kSideBorder(255, 255, 255, 89);
const QColor kSurface(13, 13, 13);

qreal lerp(qreal a, qreal b, qreal t)
{
    return a + (b - a) * t;
}

QRectF lerpRect(const QRectF &a, const QRectF &b, qreal t)
{
    return QRectF(lerp(a.x(), b.x(), t), lerp(a.y(), b.y(), t),
                  lerp(a.width(), b.width(), t), lerp(a.height(), b.height(), t));
}

QRectF coverSource(const QSize &image, const QRectF &target)
{
    if (image.isEmpty() || target.isEmpty())
        return {};

    const qreal scale = std::max(target.width() / image.width(),
                                 target.height() / image.height());
    const qreal w = target.width() / scale;
    const qreal h = target.height() / scale;
    return QRectF((image.width() - w) / 2.0, (image.height() - h) / 2.0, w, h);
}

QString quoteForShell(const QString &path)
{
    QString escaped = path;
    escaped.replace('\\', "\\\\");
    escaped.replace('"', "\\\"");
    escaped.replace('$', "\\$");
    escaped.replace('`', "\\`");
    return '"' + escaped + '"';
}

class WallpaperStore
{
public:
    WallpaperStore()
    {
        picturesDir = qEnvironmentVariable("WALLPAPER_PICKER_DIR");
        if (picturesDir.isEmpty())
            picturesDir = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
        if (picturesDir.isEmpty())
            picturesDir = QDir::homePath() + "/Pictures";

        stateFile = qEnvironmentVariable("WALLPAPER_PICKER_STATE");
        if (stateFile.isEmpty()) {
            QString stateHome = qEnvironmentVariable("XDG_STATE_HOME");
            if (stateHome.isEmpty())
                stateHome = QDir::homePath() + "/.local/state";
            stateFile = stateHome + "/wallpaper-picker/state.json";
        }

        loadState();
        if (currentPath.isEmpty())
            currentPath = runningSwaybgPath();
        scan();
    }

    QStringList entries;
    QString currentPath;
    QString picturesDir;
    QString stateFile;

    void scan()
    {
        entries.clear();
        QDir root(picturesDir);
        if (!root.exists())
            return;

        const QStringList filters = {"*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"};
        QDirIterator it(picturesDir, filters, QDir::Files | QDir::Readable,
                        QDirIterator::Subdirectories);
        while (it.hasNext()) {
            const QString path = it.next();
            const QString rel = root.relativeFilePath(path);
            if (rel.count('/') > 1)
                continue;
            if (rel.contains("Screenshots/", Qt::CaseInsensitive))
                continue;
            entries.append(path);
        }

        std::sort(entries.begin(), entries.end(), [](const QString &a, const QString &b) {
            return QString::localeAwareCompare(a, b) < 0;
        });

        if (!currentPath.isEmpty() && !entries.contains(currentPath))
            currentPath.clear();
        if (currentPath.isEmpty() && !entries.isEmpty())
            currentPath = entries.first();
    }

    int currentIndex() const
    {
        return entries.indexOf(currentPath);
    }

    void apply(const QString &path)
    {
        if (path.isEmpty())
            return;

        currentPath = path;
        saveState();
        runBackend(path);
    }

    void random()
    {
        if (entries.isEmpty())
            return;
        const int index = QRandomGenerator::global()->bounded(entries.size());
        apply(entries.at(index));
    }

private:
    // Adopt the wallpaper that is already on screen (swaybg's -i argument)
    // when this application has never persisted a choice.
    static QString runningSwaybgPath()
    {
        const QStringList processes = QDir(QStringLiteral("/proc")).entryList(
            QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString &pid : processes) {
            bool numeric = !pid.isEmpty();
            for (const QChar ch : pid) {
                if (!ch.isDigit()) {
                    numeric = false;
                    break;
                }
            }
            if (!numeric)
                continue;

            QFile cmdline("/proc/" + pid + "/cmdline");
            if (!cmdline.open(QIODevice::ReadOnly))
                continue;
            const QList<QByteArray> args = cmdline.readAll().split('\0');
            if (args.isEmpty() || !args.first().endsWith("swaybg"))
                continue;
            for (int i = 0; i + 1 < args.size(); ++i) {
                if (args.at(i) == "-i")
                    return QString::fromLocal8Bit(args.at(i + 1));
            }
        }
        return {};
    }

    void loadState()
    {
        QFile file(stateFile);
        if (!file.open(QIODevice::ReadOnly))
            return;
        const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        if (!doc.isObject())
            return;
        const QString path = doc.object().value("path").toString();
        if (!path.isEmpty())
            currentPath = path;
    }

    void saveState()
    {
        const QFileInfo info(stateFile);
        QDir().mkpath(info.absolutePath());

        QFile file(stateFile);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
            return;
        const QJsonObject obj{{"path", currentPath}};
        file.write(QJsonDocument(obj).toJson(QJsonDocument::Indented));
    }

    static bool processRunning(const QString &name)
    {
        QProcess check;
        check.start("pgrep", {"-x", name});
        if (!check.waitForFinished(150))
            return false;
        return check.exitStatus() == QProcess::NormalExit && check.exitCode() == 0;
    }

    static void runBackend(const QString &path)
    {
        const QString forced = qEnvironmentVariable("WALLPAPER_PICKER_BACKEND");
        if (!forced.isEmpty()) {
            QProcess::startDetached("sh", {"-c", forced + " \"$1\"", "wallpaper-picker", path});
            return;
        }

        if (!qEnvironmentVariableIsEmpty("HYPRLAND_INSTANCE_SIGNATURE")
            && processRunning("hyprpaper")
            && !QStandardPaths::findExecutable("hyprctl").isEmpty()) {
            QProcess::startDetached("hyprctl",
                                    {"hyprpaper", "wallpaper", ", " + path});
            return;
        }

        if (processRunning("awww") && !QStandardPaths::findExecutable("awww").isEmpty()) {
            QProcess::startDetached("awww", {"img", path});
            return;
        }

        if (processRunning("swww") && !QStandardPaths::findExecutable("swww").isEmpty()) {
            QProcess::startDetached("swww", {"img", path});
            return;
        }

        // swaybg is the common denominator for niri, Sway, Mango and labwc.
        QProcess::startDetached(
            "sh",
            {"-c",
             "pkill -x swaybg 2>/dev/null; sleep 0.12; exec swaybg -i \"$1\" -m fill",
             "wallpaper-picker", path});
    }
};

struct CellLayout
{
    QRectF rect;
    qreal opacity = 0;
    bool visible = false;
};

using Layout = QHash<int, CellLayout>;

class WallpaperWindow final : public QWidget
{
    Q_OBJECT

public:
    explicit WallpaperWindow(WallpaperStore *store, QWidget *parent = nullptr)
        : QWidget(parent)
        , m_store(store)
    {
        setAttribute(Qt::WA_TranslucentBackground);
        setAttribute(Qt::WA_NoSystemBackground);
        setAutoFillBackground(false);
        setWindowFlags(Qt::FramelessWindowHint);
        setMouseTracking(true);
        setFocusPolicy(Qt::StrongFocus);

        if (m_store->entries.isEmpty())
            m_selected = -1;
        else {
            const int index = m_store->currentIndex();
            m_selected = index >= 0 ? index : 0;
        }

        loadImagesAsync();

        m_animation.setDuration(kAnimationMs);
        m_animation.setEasingCurve(QEasingCurve::OutCubic);
        connect(&m_animation, &QVariantAnimation::valueChanged, this, [this](const QVariant &v) {
            m_progress = v.toReal();
            update();
        });
        connect(&m_animation, &QVariantAnimation::finished, this, [this]() {
            m_from = m_to;
            m_progress = 1.0;
            update();
        });
    }

    void configureLayerShell()
    {
        winId();
        QWindow *window = windowHandle();
        if (!window)
            return;

        auto *layer = LayerShellQt::Window::get(window);
        if (!layer)
            return;

        layer->setAnchors(LayerShellQt::Window::Anchors(
            LayerShellQt::Window::AnchorTop | LayerShellQt::Window::AnchorBottom
            | LayerShellQt::Window::AnchorLeft | LayerShellQt::Window::AnchorRight));
        // -1 both ignores other panels' exclusive zones and asks the
        // compositor to place this surface above them, so the top bar cannot
        // show through the full-screen backdrop.
        layer->setExclusiveZone(-1);
        layer->setLayer(LayerShellQt::Window::LayerOverlay);
        layer->setKeyboardInteractivity(
            LayerShellQt::Window::KeyboardInteractivityOnDemand);
        layer->setScope(QStringLiteral("wallpaper-picker"));
        layer->setWantsToBeOnActiveScreen(true);
    }

    void toggleVisibility()
    {
        if (isVisible()) {
            hide();
            return;
        }
        show();
        raise();
        activateWindow();
        setFocus();
    }

protected:
    void resizeEvent(QResizeEvent *event) override
    {
        QWidget::resizeEvent(event);
        m_to = layoutFor(m_selected);
        m_from = m_to;
        m_animation.stop();
        m_progress = 1.0;
        update();
    }

    void paintEvent(QPaintEvent *) override
    {
        QPainter painter(this);
        painter.setRenderHint(QPainter::Antialiasing);
        painter.setRenderHint(QPainter::SmoothPixmapTransform);

        // Full-screen, dimmed preview of the current choice.
        if (m_selected >= 0 && m_selected < m_store->entries.size()) {
            const QImage &backdrop = m_images.value(m_store->entries.at(m_selected));
            if (!backdrop.isNull()) {
                painter.drawImage(rect(), backdrop,
                                  coverSource(backdrop.size(), QRectF(rect())));
            }
        }
        painter.fillRect(rect(), QColor(0, 0, 0, 184));

        if (m_store->entries.isEmpty()) {
            painter.setPen(QColor(235, 235, 235));
            painter.setFont(QFont(QStringLiteral("monospace"), 14));
            painter.drawText(rect(), Qt::AlignCenter,
                             QStringLiteral("No wallpapers found in ")
                                 + m_store->picturesDir);
            return;
        }

        const Layout current = currentLayout();
        const int activeIndex = m_progress < 0.5 && m_previous >= 0
            ? m_previous
            : m_selected;

        // Far slices first, active card last.
        QList<int> order;
        for (auto it = current.cbegin(); it != current.cend(); ++it) {
            if (it.value().visible)
                order.append(it.key());
        }
        std::sort(order.begin(), order.end(), [&](int a, int b) {
            const auto cellA = current.value(a);
            const auto cellB = current.value(b);
            const qreal da = std::abs(cellA.rect.center().x() - width() / 2.0);
            const qreal db = std::abs(cellB.rect.center().x() - width() / 2.0);
            return da > db;
        });

        for (int index : order) {
            const CellLayout cell = current.value(index);
            const bool active = index == activeIndex;
            painter.save();
            painter.setOpacity(cell.opacity);

            // The selected card is the raw wallpaper: no surface fill under
            // it, no border and no tint. Only the receding side slices keep a
            // 1px hairline, a dark backing, and the slight outward lean.
            const QRectF frame = cell.rect;
            const qreal slant = active
                ? 0.0
                : (frame.center().x() < width() / 2.0 ? -kSideSlant : kSideSlant);

            painter.translate(frame.topLeft());
            if (!qFuzzyIsNull(slant))
                painter.shear(slant, 0);
            const QRectF local(0, 0, frame.width(), frame.height());

            if (!active)
                painter.fillRect(local, kSurface);

            const QImage &image = m_images.value(m_store->entries.at(index));
            if (!image.isNull()) {
                const int border = active ? 0 : 1;
                const QRectF target = local.adjusted(border, border, -border, -border);
                painter.setClipRect(target);
                painter.drawImage(target, image, coverSource(image.size(), target));
                painter.setClipping(false);
            }

            if (!active) {
                painter.setPen(QPen(kSideBorder, 1.0));
                painter.setBrush(Qt::NoBrush);
                painter.drawRect(local.adjusted(0.5, 0.5, -0.5, -0.5));
            }
            painter.restore();
        }
    }

    void keyPressEvent(QKeyEvent *event) override
    {
        switch (event->key()) {
        case Qt::Key_Left:
        case Qt::Key_Up:
        case Qt::Key_H:
        case Qt::Key_K:
            move(-1);
            break;
        case Qt::Key_Right:
        case Qt::Key_Down:
        case Qt::Key_L:
        case Qt::Key_J:
            move(1);
            break;
        case Qt::Key_Escape:
            close();
            break;
        case Qt::Key_Return:
        case Qt::Key_Enter:
            applyAndClose();
            break;
        default:
            QWidget::keyPressEvent(event);
        }
    }

    void wheelEvent(QWheelEvent *event) override
    {
        move(event->angleDelta().y() < 0 ? 1 : -1);
        event->accept();
    }

    void mousePressEvent(QMouseEvent *event) override
    {
        if (event->button() != Qt::LeftButton) {
            QWidget::mousePressEvent(event);
            return;
        }

        const Layout current = currentLayout();
        QList<int> order;
        for (auto it = current.cbegin(); it != current.cend(); ++it) {
            if (it.value().visible)
                order.append(it.key());
        }
        std::sort(order.begin(), order.end(), [&](int a, int b) {
            const qreal da = std::abs(current.value(a).rect.center().x() - width() / 2.0);
            const qreal db = std::abs(current.value(b).rect.center().x() - width() / 2.0);
            return da < db;
        });

        for (int index : order) {
            if (!current.value(index).rect.contains(event->position()))
                continue;
            if (index == m_selected)
                applyAndClose();
            else
                select(index);
            return;
        }

        close();
    }

private:
    void loadImagesAsync()
    {
        QStringList paths = m_store->entries;
        auto *watcher = new QFutureWatcher<QHash<QString, QImage>>(this);
        connect(watcher, &QFutureWatcher<QHash<QString, QImage>>::finished, this,
                [this, watcher]() {
                    const auto loaded = watcher->result();
                    for (auto it = loaded.cbegin(); it != loaded.cend(); ++it)
                        m_images.insert(it.key(), it.value());
                    watcher->deleteLater();
                    update();
                });

        watcher->setFuture(QtConcurrent::run([paths]() {
            QHash<QString, QImage> loaded;
            for (const QString &path : paths) {
                QImageReader reader(path);
                reader.setAutoTransform(true);
                const QSize original = reader.size();
                if (original.isValid())
                    reader.setScaledSize(original.scaled(1400, 900, Qt::KeepAspectRatio));
                QImage image = reader.read();
                if (!image.isNull())
                    loaded.insert(path, image);
            }
            return loaded;
        }));
    }

    void move(int delta)
    {
        if (m_store->entries.isEmpty())
            return;
        const int n = m_store->entries.size();
        select(((m_selected + delta) % n + n) % n);
    }

    void select(int index)
    {
        if (index < 0 || index >= m_store->entries.size() || index == m_selected)
            return;

        m_from = currentLayout();
        m_previous = m_selected;
        m_selected = index;
        m_to = layoutFor(m_selected);
        m_progress = 0.0;
        m_animation.stop();
        m_animation.setStartValue(0.0);
        m_animation.setEndValue(1.0);
        m_animation.start();

        // Live-preview and persist immediately, matching the shell picker.
        m_store->apply(m_store->entries.at(index));
        update();
    }

    Layout layoutFor(int selected) const
    {
        Layout layout;
        const int n = m_store->entries.size();
        if (n == 0)
            return layout;

        const qreal cardH = std::round(height() * 0.57);
        const qreal cardW = std::round(cardH * 1.62);
        const qreal sideH = std::round(cardH * kSideHeight);
        const qreal centerX = width() / 2.0;
        const qreal centerY = height() / 2.0;

        auto sideWidth = [cardW](int distance) {
            return std::round(cardW * kSideWidth
                              * std::pow(kSideShrink, distance - 1));
        };
        auto edgeOffset = [cardW, &sideWidth](int distance) {
            qreal offset = cardW / 2.0 + kGap;
            for (int k = 1; k < distance; ++k)
                offset += sideWidth(k) + kGap;
            return offset;
        };

        for (int index = 0; index < n; ++index) {
            int d = index - selected;
            if (n > 2 * kVisibleSide) {
                d = ((d % n) + n) % n;
                if (d > n / 2)
                    d -= n;
            }

            const int distance = std::abs(d);
            const bool active = distance == 0;
            const qreal w = active ? cardW : sideWidth(distance);
            const qreal h = active ? cardH : sideH;
            qreal x;
            if (active)
                x = centerX - w / 2.0;
            else if (d < 0)
                x = centerX - edgeOffset(distance) - w;
            else
                x = centerX + edgeOffset(distance);

            CellLayout cell;
            cell.rect = QRectF(std::round(x), std::round(centerY - h / 2.0),
                               w, h);
            cell.opacity = active ? 1.0 : std::max(0.5, 1.0 - 0.14 * distance);
            cell.visible = distance <= kVisibleSide;
            layout.insert(index, cell);
        }
        return layout;
    }

    Layout currentLayout() const
    {
        if (m_animation.state() != QAbstractAnimation::Running || m_progress >= 1.0)
            return m_to;

        Layout result;
        QSet<int> keys;
        for (auto it = m_from.cbegin(); it != m_from.cend(); ++it)
            keys.insert(it.key());
        for (auto it = m_to.cbegin(); it != m_to.cend(); ++it)
            keys.insert(it.key());

        const qreal t = m_progress;
        for (int key : keys) {
            const CellLayout a = m_from.value(key);
            const CellLayout b = m_to.value(key);
            CellLayout cell;
            cell.rect = lerpRect(a.rect, b.rect, t);
            cell.opacity = lerp(a.opacity, b.opacity, t);
            cell.visible = a.visible || b.visible;
            result.insert(key, cell);
        }
        return result;
    }

    void applyAndClose()
    {
        if (m_selected >= 0 && m_selected < m_store->entries.size())
            m_store->apply(m_store->entries.at(m_selected));
        close();
    }

    WallpaperStore *m_store;
    QHash<QString, QImage> m_images;

    int m_selected = -1;
    int m_previous = -1;
    Layout m_from;
    Layout m_to;
    qreal m_progress = 1.0;
    QVariantAnimation m_animation;
};

QString instanceKey()
{
    QString display = qEnvironmentVariable("WAYLAND_DISPLAY");
    if (display.isEmpty())
        display = QStringLiteral("default");
    display.replace('/', '_');
    return QStringLiteral("wallpaper-picker-") + display;
}

} // namespace

int main(int argc, char **argv)
{
    QCoreApplication::setApplicationName(QStringLiteral("wallpaper-picker"));
    QCoreApplication::setOrganizationName(QStringLiteral("wallpaper-picker"));
    QCoreApplication::setApplicationVersion(QStringLiteral("0.1.0"));

    if (!qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY"))
        qputenv("QT_WAYLAND_SHELL_INTEGRATION", "layer-shell");

    QApplication app(argc, argv);

    QCommandLineParser parser;
    parser.setApplicationDescription(
        QStringLiteral("A compositor-portable wallpaper carousel for wlroots "
                       "(niri, Hyprland, Sway, Mango, labwc)."));
    parser.addHelpOption();
    parser.addVersionOption();

    const QCommandLineOption listOption("list", "Print every discovered wallpaper.");
    const QCommandLineOption getOption("get", "Print the selected wallpaper.");
    const QCommandLineOption setOption("set", "Apply a wallpaper.", "path");
    const QCommandLineOption randomOption("random", "Apply a random wallpaper.");
    const QCommandLineOption openOption("open", "Force-open the carousel.");
    const QCommandLineOption toggleOption("toggle", "Toggle the carousel (default).");
    parser.addOption(listOption);
    parser.addOption(getOption);
    parser.addOption(setOption);
    parser.addOption(randomOption);
    parser.addOption(openOption);
    parser.addOption(toggleOption);
    parser.process(app);

    WallpaperStore store;

    if (parser.isSet(listOption)) {
        for (const QString &path : store.entries)
            printf("%s\n", qUtf8Printable(path));
        return 0;
    }
    if (parser.isSet(getOption)) {
        printf("%s\n", qUtf8Printable(store.currentPath));
        return 0;
    }
    if (parser.isSet(setOption)) {
        QString path = parser.value(setOption);
        const QFileInfo info(path);
        path = info.exists() ? info.absoluteFilePath() : path;
        store.apply(path);
        printf("%s\n", qUtf8Printable(path));
        return 0;
    }
    if (parser.isSet(randomOption)) {
        store.random();
        printf("%s\n", qUtf8Printable(store.currentPath));
        return 0;
    }

    if (!parser.isSet(openOption)) {
        const QString key = instanceKey();
        QLocalSocket socket;
        socket.connectToServer(key);
        if (socket.waitForConnected(120)) {
            socket.write("toggle\n");
            socket.waitForBytesWritten(120);
            socket.disconnectFromServer();
            return 0;
        }
    }

    WallpaperWindow window(&store);
    window.configureLayerShell();

    QLocalServer server;
    server.setSocketOptions(QLocalServer::UserAccessOption);
    QLocalServer::removeServer(instanceKey());
    server.listen(instanceKey());
    QObject::connect(&server, &QLocalServer::newConnection, &window, [&server, &window]() {
        while (QLocalSocket *socket = server.nextPendingConnection()) {
            QObject::connect(socket, &QLocalSocket::readyRead, socket,
                             [socket, &window]() {
                                 if (socket->readAll().contains("toggle"))
                                     window.toggleVisibility();
                             });
            QObject::connect(socket, &QLocalSocket::disconnected, socket,
                             &QObject::deleteLater);
        }
    });

    window.show();
    window.raise();
    window.activateWindow();
    window.setFocus();
    QTimer::singleShot(30, &window, [&window]() { window.setFocus(); });

    return app.exec();
}

#include "main.moc"
