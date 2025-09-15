#ifndef UDPSLAVE_H
#define UDPSLAVE_H

#include <QObject>
#include <QUdpSocket>
#include <QTimer>
#include <QHostAddress>
#include <QImage>
#include <QUrl>
#include <QUuid>

// Include PeopleModel
#include "peoplemodel.h"

// Quando invio il pacchetto "people" lo spezzo in parti e ne tengo traccia qui.
struct OutgoingTransfer {
    QString id;
    QList<QByteArray> datagrams; // JSON già pronto (uno per seq)
    int nextToSend = 0;
};

// Oggetto creato da QML sul tablet/telefonino per parlare col master in broadcast.
class UdpSlave : public QObject {
    Q_OBJECT

public:
    explicit UdpSlave(QObject* parent = nullptr);   // <— costruttore di default per QML

    Q_INVOKABLE void start(QString name, QString lastname, QUrl image);
    Q_INVOKABLE void stop();
    Q_INVOKABLE void sendBid(int amount);

signals:
    void masterFound(const QHostAddress& addr, quint16 port);
    void sentPeople();
    void errorChanged(const QString& msg);
    void peopleModelChanged();

private slots:
    void onTick();
    void onReadyRead();

private:
    QUdpSocket m_sock;
    QTimer m_timer;
    // Flag di stato per non bombardare il master mentre aspetto gli ACK.
    bool m_waitingAckFind = false;
    bool m_waitingAckPeople = false;
    QHostAddress m_masterAddr;
    quint16 m_masterPort = 0;

    // Mi preparo il JSON completo da spezzare quando trovo il master.
    QByteArray data_to_send;

    static constexpr quint16 PORT = 58000;
    static constexpr int PERIOD_MS = 1000;

    OutgoingTransfer m_out;
    // Timer veloce che mi permette di scaglionare l'invio dei datagrammi senza saturare la rete.
    QTimer m_burstTimer; // per pacing burst

    // Una volta registrato il master mi assegna un ID che riutilizzo per le puntate.
    int unique_id = 0;

    void sendFind();
    void sendPeople();
};

#endif // UDPSLAVE_H
