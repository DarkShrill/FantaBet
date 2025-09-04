#ifndef UDPMASTER_H
#define UDPMASTER_H

#include <QObject>
#include <QUdpSocket>
#include <QHostAddress>
#include <QMap>
#include <QVector>
#include <QElapsedTimer>
#include <QRandomGenerator>

struct PendingTransfer {
    int total = 0;
    int received = 0;
    QVector<QByteArray> parts;
    QElapsedTimer timer;           // per timeout
    QHostAddress lastSender;
    quint16      lastPort = 0;
};

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
    QMap<QString, PendingTransfer> m_transfers;
    QVector<int> unique_ids_list;

};

#endif // UDPMASTER_H
