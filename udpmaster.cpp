#include "udpmaster.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>
#include <QJsonArray>

UdpMaster::UdpMaster(QObject* parent) : QObject(parent) {
    // Permetti riuso porta (utile se più processi/dev su stessa macchina)
    if (!m_sock.bind(QHostAddress::AnyIPv4, PORT,
        QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
        qWarning() << "Bind UDP fallito su" << PORT << m_sock.errorString();
    }
    connect(&m_sock, &QUdpSocket::readyRead, this, &UdpMaster::onReadyRead);
    qInfo() << "[MASTER] in ascolto su UDP" << PORT;

    m_sock.setSocketOption(QAbstractSocket::SendBufferSizeSocketOption,   4*1024*1024);
    m_sock.setSocketOption(QAbstractSocket::ReceiveBufferSizeSocketOption,4*1024*1024);
}

void UdpMaster::onReadyRead() {
    while (m_sock.hasPendingDatagrams()) {
        QByteArray buf;
        buf.resize(int(m_sock.pendingDatagramSize()));
        QHostAddress sender; quint16 sport=0;
        m_sock.readDatagram(buf.data(), buf.size(), &sender, &sport);

        const auto doc = QJsonDocument::fromJson(buf);
        if (!doc.isObject()) continue;
        const auto obj = doc.object();
        const auto type = obj.value("type").toString();

        if (type == "find") {
            qInfo() << "[MASTER] FIND da" << sender.toString() << ":" << sport;
            sendAck(sender, sport, "find");
        } else if (type == "people") {
            int count = obj.value("count").toInt();
            const QJsonArray payload = obj.value("payload").toArray();
            qInfo() << "[MASTER] PEOPLE (" << count << " record ) da" << sender.toString() << ":" << sport;

            //emit peopleReceived(payload);

            //sendAck(sender, sport, "people"); // ACK OK
        } else if (type == "bid") {
            int who    = obj.value("who").toInt();
            int amount = obj.value("amount").toInt();

            qInfo() << "[MASTER] BID da" << sender << ":" << sport
                    << "who=" << who << "amount=" << amount;

            emit bidReceived(who, amount);

            sendAck(sender, sport, "bid"); // se vuoi confermare
        } else if (type == "people_part") {
            const QString id   = obj.value("id").toString();
            const int seq      = obj.value("seq").toInt();
            const int total    = obj.value("total").toInt();
            const QString dataB64 = obj.value("data").toString();

            if (id.isEmpty() || total <= 0 || total > 8192 || seq < 0 || seq >= total) {
                qWarning() << "[MASTER] people_part invalido";
                continue;
            }

            //qInfo() << "[MASTER] people_part " << id << " " << seq << " " << total;

            QByteArray data = QByteArray::fromBase64(dataB64.toLatin1());

            auto &t = m_transfers[id];
            if (t.parts.isEmpty()) {
                t.total = total;
                t.parts.resize(total);
                t.timer.start();
            } else if (t.total != total) {
                qWarning() << "[MASTER] total incoerente per id" << id;
                m_transfers.remove(id);
                continue;
            }

            t.lastSender = sender;
            t.lastPort   = sport;

            if (t.parts[seq].isEmpty()) {
                t.parts[seq] = std::move(data);
                ++t.received;
            } // else: duplicato → ignora

            // se completo → assembla, emetti e ACK finale
            if (t.received == t.total) {
                QByteArray full;
                for (const auto &p : t.parts) full.append(p);
                m_transfers.remove(id);


                int randomNumber = getRandomNumber();

                const QJsonDocument doc = QJsonDocument::fromJson(full);
                if (doc.isObject()) {
                    const QJsonObject people = doc.object();
                    emit peopleReceived(people.value("payload").toArray(), randomNumber);
                } else {
                    qWarning() << "[MASTER] JSON completo non valido";
                }


                sendAck(sender, sport, "people", randomNumber);
                continue;
            }

            // timeout/ritrasmissione: ogni ~300ms controlla pezzi mancanti
            if (t.timer.elapsed() > 300) {
                t.timer.restart();
                QVector<int> missing;
                missing.reserve(t.total - t.received);
                for (int i = 0; i < t.total; ++i)
                    if (t.parts[i].isEmpty()) missing.push_back(i);

                // chiedi solo alcuni mancanti per non esagerare (es. max 128 alla volta)
                if (!missing.isEmpty()) {
                    if (missing.size() > 128) missing.resize(128);
                    sendNack(t.lastSender, t.lastPort, id, missing);
                }
            }
        } else {
            qDebug() << "[MASTER] Ignoro type=" << type;
        }
    }
}

void UdpMaster::sendNack(const QHostAddress& to, quint16 port,
                         const QString& id, const QVector<int>& missing)
{
    QJsonArray arr;
    for (int s : missing) arr.push_back(s);

    QJsonObject obj;
    obj["type"] = "nack";
    obj["id"] = id;
    obj["missing"] = arr;

    m_sock.writeDatagram(QJsonDocument(obj).toJson(QJsonDocument::Compact), to, port);
    qInfo() << "[MASTER] NACK →" << to << ":" << port << "missing" << missing.size();
}

int UdpMaster::getRandomNumber()
{
    int randomNumber = 0;

REPEAT:
    randomNumber = QRandomGenerator::global()->bounded(1, 1025);

    if(unique_ids_list.contains(randomNumber)){
        goto REPEAT;
    }
    return randomNumber;
}

void UdpMaster::sendAck(const QHostAddress& to, quint16 port, const QString& forType, int unique_id) {
    QJsonObject ack; ack["type"]="ack"; ack["for"]=forType; ack["ok"]=true;
    if(unique_id != 0)
        ack["unique_id"] = unique_id;
    const QByteArray dat = QJsonDocument(ack).toJson(QJsonDocument::Compact);
    m_sock.writeDatagram(dat, to, port);
    qInfo() << "[MASTER] ACK("<< forType <<") →" << to.toString() << ":" << port;
}
