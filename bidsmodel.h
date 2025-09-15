#ifndef BIDSMODEL_H
#define BIDSMODEL_H


#include "playermodel.h"

#include <QAbstractListModel>
#include <QColor>
#include <QDateTime>
#include <QTimer>
#include <QVector>
#include <QDebug>

// Gestisco qui lo storico delle puntate così lo posso riutilizzare lato QML.
class BidsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(bool demoEnabled READ demoEnabled WRITE setDemoEnabled NOTIFY demoEnabledChanged)
    Q_PROPERTY(int demoIntervalMs READ demoIntervalMs WRITE setDemoIntervalMs NOTIFY demoIntervalMsChanged)

public:
    explicit BidsModel(PlayerModel * people);
    ~BidsModel() override = default;

    enum Roles {
        TimestampRole = Qt::UserRole + 1, // qint64 ms since epoch
        DeltaRole,                        // int/double
        WhoRole,                          // QString
        WhoImage,
        TotalRole                         // int totale dopo la puntata
    };
    Q_ENUM(Roles)

    // QAbstractListModel
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;

    // API QML
    // Metodo principale: aggiungo una puntata con ID giocatore e importo.
    Q_INVOKABLE int appendBid(int who, int delta, qint64 timestampMs = -1);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QVariantMap get(int row) const;

    // Demo / auto-random
    bool demoEnabled() const { return m_demoTimer.isActive(); }
    void setDemoEnabled(bool on);
    int demoIntervalMs() const { return m_demoTimer.interval(); }
    void setDemoIntervalMs(int ms);

signals:
    void countChanged();
    void demoEnabledChanged();
    void demoIntervalMsChanged();

private slots:
    void addRandomBid();

private:
    struct Bid {
        qint64  timestampMs = 0;
        int     amount       = 0;
        Player  who;
        int     totalAfter  = 0;   // totale DOPO aver applicato delta
    };

    // Tengo un puntatore al modello dei player per recuperare velocemente i nomi/foto.
    PlayerModel *people = nullptr;

    int currentTotal() const { return m_total; }

    QVector<Bid> m_items;  // newest first (row 0)
    int m_total = 0;

    // Timer interno per la modalità demo: mi torna utile per fare vedere il flusso.
    QTimer m_demoTimer;
    QString randomName() const;
    int randomDelta() const;

    Player * getPlayerFromUniqueId(int who);
};

#endif // BIDSMODEL_H
