#include "bidsmodel.h"
#include "peoplemodel.h"
#include "playermodel.h"
#include "udpmaster.h"
#include "udpslave.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QTimer>
#include <QQmlApplicationEngine>
#include <QSurfaceFormat>

static PlayerModel * model = nullptr;
static BidsModel * g_bids = nullptr;
static PeopleModel * p_model = nullptr;

static QObject* Get_PeopleModelProvider(QQmlEngine* engine, QJSEngine* scriptEngine) {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    if(p_model == nullptr){
        p_model = new PeopleModel();
        // opzionale: evita che QML prenda ownership
        QQmlEngine::setObjectOwnership(p_model, QQmlEngine::CppOwnership);
    }
    return p_model;
}

// Provider che crea l'istanza singleton
static QObject* Get_PlayersSingleton(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    if(model == nullptr){
        model = new PlayerModel();
        // opzionale: evita che QML prenda ownership
        QQmlEngine::setObjectOwnership(model, QQmlEngine::CppOwnership);
    }
    return model;
}

static QObject* Get_BidsProvider(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    if(model == nullptr){
        model = new PlayerModel();
        // opzionale: evita che QML prenda ownership
        QQmlEngine::setObjectOwnership(model, QQmlEngine::CppOwnership);
    }
    if (!g_bids) {
        g_bids = new BidsModel(model);
        QQmlEngine::setObjectOwnership(g_bids, QQmlEngine::CppOwnership);
    }


    return g_bids;
}

int main(int argc, char *argv[])
{
    QCoreApplication::setOrganizationName("DarkShrill");
    QCoreApplication::setOrganizationDomain("DarkShrill");
    QCoreApplication::setApplicationName("FantaBet");

/*
    QSurfaceFormat fmt;
    fmt.setRenderableType(QSurfaceFormat::OpenGL);
    QSurfaceFormat::setDefaultFormat(fmt);
*/

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);

    qmlRegisterSingletonType<PlayerModel>("App", 1, 0, "Players", Get_PlayersSingleton);
    qmlRegisterSingletonType<BidsModel>("App", 1, 0, "Bids", Get_BidsProvider);

    qmlRegisterSingletonType<PeopleModel>("App", 1, 0, "PeopleModel",
                                          Get_PeopleModelProvider);

    qmlRegisterType<UdpMaster>("Network", 1, 0, "UdpMaster");
    qmlRegisterType<UdpSlave>("Network", 1, 0, "UdpSlave");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

//    Get_PlayersSingleton(NULL,NULL);

    // Popola con persone di default
//    model->append("Mario", "Rossi",   "qrc:/avatar.png", QColor("#e63946"), 0.0);
//    model->append("Luca",  "Bianchi", "qrc:/avatar.png", QColor("#f1fa8c"), 0.12);
//    model->append("Anna",  "Verdi",   "qrc:/avatar.png", QColor("#2a9d8f"), 0.24);

    // Dopo 5 secondi aggiungi un nuovo player
//    QTimer::singleShot(5000, [&]() {
//        model->append("Giulia", "Neri", "", QColor("#457b9d"), 0.32);
//    });

    return app.exec();
}
