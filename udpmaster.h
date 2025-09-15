#ifndef UDPMASTER_H
#define UDPMASTER_H

#include <QObject>
#include <QUdpSocket>
#include <QHostAddress>
#include <QMap>
#include <QVector>
#include <QElapsedTimer>
#include <QRandomGenerator>

// Ogni trasferimento "people" multi-pacchetto lo traccio qui per gestire ritrasmissioni e ack.
struct PendingTransfer {
    int total = 0;
    int received = 0;
    QVector<QByteArray> parts;
    QElapsedTimer timer;           // per timeout
    QHostAddress lastSender;
    quint16      lastPort = 0;
};

// Questo oggetto vive nel master e gestisce la comunicazione UDP con gli slave.
class UdpMaster : public QObject {
    Q_OBJECT
public:
    explicit UdpMaster(QObject* parent = nullptr);

private slots:
    void onReadyRead();

signals:

    void peopleReceived(const QJsonArray &payload, int unique_id);

    void bidReceived(int who, int amount);

private:
    QUdpSocket m_sock;
    static constexpr quint16 PORT = 58000;
    void sendAck(const QHostAddress& to, quint16 port, const QString& forType, int unique_id = 0);
    void sendNack(const QHostAddress& to, quint16 port, const QString& id,
                  const QVector<int>& missing);
    int getRandomNumber();
    // Mappa dei trasferimenti in corso indicizzati per ID sessione inviato dallo slave.
    QMap<QString, PendingTransfer> m_transfers;
    // Tengo a portata di mano una lista di ID nel caso volessi gestire duplicati a runtime.
    QVector<int> unique_ids_list;

};

#endif // UDPMASTER_H
