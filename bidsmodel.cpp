#include "BidsModel.h"
#include <QtGlobal>
#include <QRandomGenerator>

BidsModel::BidsModel(PlayerModel *people)
{
    this->people = people;


    // Timer demo: ogni 5 secondi aggiunge una puntata random
    m_demoTimer.setInterval(1000);
    connect(&m_demoTimer, &QTimer::timeout, this, &BidsModel::addRandomBid);

    // Avvio demo di default (disattiva se non vuoi)
//    m_demoTimer.start();
//    emit demoEnabledChanged();
//    emit demoIntervalMsChanged();
}

int BidsModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) return 0;
    return m_items.size();
}

QVariant BidsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const Bid& b = m_items.at(index.row());
    switch (role) {
    case TimestampRole: return b.timestampMs;
    case DeltaRole:     return b.amount;
    case WhoRole:       return b.who.firstName + " " + b.who.lastName;
    case WhoImage:      return b.who.avatar;
    case TotalRole:     return b.totalAfter;
    default:            return {};
    }
}

QHash<int, QByteArray> BidsModel::roleNames() const
{
    return {
        { TimestampRole, "timestamp" },
        { DeltaRole,     "amount"    },
        { WhoRole,       "who"       },
        { WhoImage,      "photo"     },
        { TotalRole,     "total"     }
    };
}

Qt::ItemFlags BidsModel::flags(const QModelIndex& index) const
{
    if (!index.isValid()) return Qt::NoItemFlags;
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable;
}

int BidsModel::appendBid(int who, int delta, qint64 timestampMs)
{
    if (timestampMs < 0)
        timestampMs = QDateTime::currentMSecsSinceEpoch();

    Player* pl = people->getPlayerFromUniqueId(who);
    if (!pl) {
        qWarning() << "[BidsModel] Player id" << who << "non trovato";
        return -1;
    }

    Bid b;
    b.timestampMs = timestampMs;
    b.amount      = delta;
    b.who         = *pl;
    b.totalAfter  = m_total + delta;

    // Inseriamo in TESTA (riga 0) per avere il più recente in alto
    beginInsertRows(QModelIndex(), 0, 0);
    m_items.prepend(b);
    endInsertRows();

    m_total = b.totalAfter;

    emit countChanged();
    // NOTA: la tua pagina QML si aggancia a onRowsInserted per resettare il timer
    return 0;
}

void BidsModel::clear()
{
    if (m_items.isEmpty()) return;
    beginResetModel();
    m_items.clear();
    m_total = 0;
    endResetModel();
    emit countChanged();
}

QVariantMap BidsModel::get(int row) const
{
    QVariantMap m;
    if (row < 0 || row >= m_items.size()) return m;
    const Bid& b = m_items.at(row);
    m.insert("timestamp", b.timestampMs);
    m.insert("delta",     b.amount);
    m.insert("who",       b.who.firstName + " " + b.who.lastName);
    m.insert("photo",     b.who.avatar);
    m.insert("total",     b.totalAfter);
    return m;
}

/* ===== Demo / auto random ===== */

void BidsModel::setDemoEnabled(bool on)
{
    if (on == m_demoTimer.isActive()) return;
    if (on) m_demoTimer.start();
    else    m_demoTimer.stop();
    emit demoEnabledChanged();
}

void BidsModel::setDemoIntervalMs(int ms)
{
    if (ms <= 0 || ms == m_demoTimer.interval()) return;
    m_demoTimer.setInterval(ms);
    emit demoIntervalMsChanged();
}

void BidsModel::addRandomBid()
{
//    const QString who = randomName();
//    const int delta   = randomDelta();
//    appendBid(who, delta, QDateTime::currentMSecsSinceEpoch());

//    if(m_items.size() > 3){
//        setDemoEnabled(false);
//    }
}

QString BidsModel::randomName() const
{
    static const QStringList first = {
        "Luca","Marco","Anna","Giulia","Edo","Sara","Marta","Paolo","Vale","Gio"
    };
    static const QStringList last = {
        "Rossi","Bianchi","Verdi","Neri","Costa","Ferrari","Moretti","Galli","Greco","Fontana"
    };

#if QT_VERSION >= QT_VERSION_CHECK(5,10,0)
    int i = QRandomGenerator::global()->bounded(first.size());
    int j = QRandomGenerator::global()->bounded(last.size());
#else
    int i = qrand() % first.size();
    int j = qrand() % last.size();
#endif
    return first.at(i) + " " + last.at(j);
}

int BidsModel::randomDelta() const
{
    // valori tipici di rilancio
    static const int deltas[] = {1, 2, 5, 10, 20, 50};
#if QT_VERSION >= QT_VERSION_CHECK(5,10,0)
    int k = QRandomGenerator::global()->bounded(int(sizeof(deltas)/sizeof(deltas[0])));
#else
    int k = qrand() % (int(sizeof(deltas)/sizeof(deltas[0])));
#endif
    return deltas[k];
}

Player *BidsModel::getPlayerFromUniqueId(int who)
{
    return people->getPlayerFromUniqueId(who);
}
