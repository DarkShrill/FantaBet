#include "udpslave.h"
#include "peoplemodel.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkInterface>
#include <QDebug>
#include <QImage>
#include <QBuffer>

UdpSlave::UdpSlave(QObject* parent) : QObject(parent) {
    // porta effimera per ricevere ACK; specifica la bind mode per evitare ambiguità
    if (!m_sock.bind(QHostAddress::AnyIPv4, 0,
                     QUdpSocket::DefaultForPlatform)) {
        emit errorChanged(QStringLiteral("Bind UDP failed: %1").arg(m_sock.errorString()));
    }
    connect(&m_sock, &QUdpSocket::readyRead, this, &UdpSlave::onReadyRead);
    m_timer.setInterval(PERIOD_MS);
    connect(&m_timer, &QTimer::timeout, this, &UdpSlave::onTick);

    // Anche qui aumento i buffer per reggere il burst iniziale del trasferimento "people".
    m_sock.setSocketOption(QAbstractSocket::SendBufferSizeSocketOption,   4*1024*1024);
    m_sock.setSocketOption(QAbstractSocket::ReceiveBufferSizeSocketOption,4*1024*1024);
}


static QString qimageToDataUrl(const QImage &img, const char *format = "PNG")
{
    QByteArray ba;
    QBuffer buffer(&ba);
    buffer.open(QIODevice::WriteOnly);
    img.save(&buffer, format);  // salva in memoria
    QString base64 = QString::fromLatin1(ba.toBase64());
    return QStringLiteral("data:image/%1;base64,%2")
            .arg(QString::fromLatin1(format).toLower(), base64);
}

void UdpSlave::start(QString name, QString lastname, QUrl image)
{

    m_masterAddr = QHostAddress();
    m_masterPort = 0;
    m_waitingAckFind = false;
    m_waitingAckPeople = false;

    QJsonArray arr;
    QJsonObject o;


    QString photoDataUrl;
    if (!image.isEmpty()) {
        const QString path = image.isLocalFile()
                           ? image.toLocalFile()
                           : image.toString(); // gestisce anche qrc:/...
        QImage img(path);
        if (!img.isNull()) {
            // Converto la foto in data URL così posso incapsularla nel JSON senza passaggi extra.
            photoDataUrl = qimageToDataUrl(img, "PNG");
        }
    }

    o["firstName"] = name;
    o["lastName"]  = lastname;
    o["photo"]     = photoDataUrl;


    arr.push_back(o);

    QJsonObject root;
    root["type"] = "people";
    root["count"] = 1;
    root["payload"] = arr;

    // Mi salvo il JSON completo: lo userò quando scatterà il burst verso il master.
    data_to_send = QJsonDocument(root).toJson(QJsonDocument::Compact);


    m_timer.start();
    // Inizio subito il ciclo di discover: appena trovo il master passo all'invio dati.
    sendFind();
}

void UdpSlave::stop() {
    m_timer.stop();
    m_waitingAckFind = false;
    m_waitingAckPeople = false;
}

void UdpSlave::sendBid(int amount)
{
    QJsonObject obj;
    obj["type"]   = "bid";
    obj["who"]    = this->unique_id;
    obj["amount"] = amount;

    QByteArray dat = QJsonDocument(obj).toJson(QJsonDocument::Compact);

    if (m_masterAddr.isNull()) {
        qWarning() << "[SLAVE] Nessun master trovato, impossibile inviare bid";
        return;
    }

    m_sock.writeDatagram(dat, m_masterAddr, PORT);
    // Mi piace loggare anche qui per avere una traccia delle puntate inviate.
    qInfo() << "[SLAVE] BID inviato:" << dat;
}

void UdpSlave::onTick() {
    if (!m_waitingAckPeople) sendFind();
}

void UdpSlave::sendFind() {
    QJsonObject obj; obj["type"]="find";
    const QByteArray dat = QJsonDocument(obj).toJson(QJsonDocument::Compact);

    // Cerco tutte le interfacce attive così da inviare il discover solo dove ha senso.
    bool okAny = false;
    for (const QNetworkInterface& ifc : QNetworkInterface::allInterfaces()) {
        if (!(ifc.flags() & QNetworkInterface::IsUp) ||
            !(ifc.flags() & QNetworkInterface::IsRunning) ||
            (ifc.flags() & QNetworkInterface::IsLoopBack))
            continue;
        for (const QNetworkAddressEntry& e : ifc.addressEntries()) {
            if (e.ip().protocol() != QAbstractSocket::IPv4Protocol) continue;
            QHostAddress bcast = e.broadcast();
            if (bcast.isNull()) bcast = QHostAddress::Broadcast;
            m_sock.writeDatagram(dat, bcast, PORT);
            okAny = true;
        }
    }
    if (!okAny) {
        // In caso di interfacce "strane" faccio comunque un broadcast generico.
        m_sock.writeDatagram(dat, QHostAddress::Broadcast, PORT);
    }
    m_waitingAckFind = true;
    qInfo() << "[SLAVE] FIND broadcast inviato";
}

void UdpSlave::onReadyRead() {
    while (m_sock.hasPendingDatagrams()) {
        QByteArray buf; buf.resize(int(m_sock.pendingDatagramSize()));
        QHostAddress sender; quint16 sport=0;
        m_sock.readDatagram(buf.data(), buf.size(), &sender, &sport);

        const auto doc = QJsonDocument::fromJson(buf);
        if (!doc.isObject()) continue;
        const auto obj = doc.object();
        const QString type = obj.value("type").toString();

        if (type == "ack") {
            const QString forType = obj.value("for").toString();
            const bool ok = obj.value("ok").toBool();

            if (forType == "find" && ok && !m_waitingAckPeople) {
                // Appena il master risponde al find memorizzo l'indirizzo e mi preparo a spedire i dati.
                m_masterAddr = sender;
                m_masterPort = sport;
                m_waitingAckFind = false;
                m_timer.stop();
                emit masterFound(sender, sport);
                qInfo() << "[SLAVE] ACK(FIND) da" << sender << ":" << sport;
                sendPeople();
            } else if (forType == "people" && ok && m_waitingAckPeople) {
                m_waitingAckPeople = false;

                this->unique_id = obj.value("unique_id").toInt();

                emit sentPeople();
                // Ora che ho l'ID assegnato posso procedere con i bid veri e propri.
                qInfo() << "[SLAVE] ACK(PEOPLE) ricevuto " << unique_id;
            }
        }else if (type == "nack") {
            const QString id = obj.value("id").toString();
            if (id != m_out.id) return; // non è la nostra sessione
            const QJsonArray missing = obj.value("missing").toArray();
            // ritrasmetti solo quelli richiesti
            for (const auto &v : missing) {
                const int seq = v.toInt();
                if (seq >= 0 && seq < m_out.datagrams.size()) {
                    m_sock.writeDatagram(m_out.datagrams[seq], m_masterAddr, PORT);
                }
            }
            // opzionale: se il master continua a chiedere pochi mancanti, puoi ridurre l'intervallo
        }
    }
}

void UdpSlave::sendPeople() {
    if (m_masterAddr.isNull() || data_to_send.isEmpty()) return;

    m_out = OutgoingTransfer{};
    m_out.id = QUuid::createUuid().toString(QUuid::WithoutBraces);

    // ATTENZIONE: Base64 aumenta del ~33%. Tieni chunk **piccoli** (es. 900 byte raw)
    const int chunkSize = 900; // tengo i pacchetti piccoli per non frammentarli a livello UDP.
    const int size = data_to_send.size();
    const int total = (size % chunkSize == 0) ? (size / chunkSize)
                                              : (size / chunkSize + 1);

    qDebug() << "data_to_send size: " << size;
    qDebug() << "data_to_send total: " << total;

    m_out.datagrams.reserve(total);

    for (int seq = 0; seq < total; ++seq) {
        const QByteArray chunk = data_to_send.mid(seq * chunkSize, chunkSize);

        QJsonObject part;
        part["type"]  = "people_part";
        part["id"]    = m_out.id;
        part["seq"]   = seq;
        part["total"] = total;
        part["data"]  = QString::fromLatin1(chunk.toBase64());

        m_out.datagrams.push_back(QJsonDocument(part).toJson(QJsonDocument::Compact));
    }

    qDebug() << "m_out.datagrams: " << m_out.datagrams.size();

    // pacing: invia a burst (es. 64 datagrammi ogni 10 ms)
    // Uso un lambda qui così posso controllare facilmente quanti datagrammi inviare per ciclo.
    connect(&m_burstTimer, &QTimer::timeout, this, [this](){
        const int burst = 16; // numero che mi è sembrato un buon compromesso dopo qualche prova.
        int sent = 0;
        while (m_out.nextToSend < m_out.datagrams.size() && sent < burst) {
            const QByteArray& d = m_out.datagrams[m_out.nextToSend];
            const qint64 n = m_sock.writeDatagram(d, m_masterAddr, PORT);
            if (n < 0) {
                // Se il buffer è pieno mi fermo: riproverò al prossimo tick senza stressare il socket.
                // qWarning() << "writeDatagram failed:" << m_sock.errorString();
                break;
            }
            ++m_out.nextToSend;
            ++sent;
        }
        if (m_out.nextToSend >= m_out.datagrams.size()) {
            m_burstTimer.stop();
            // Da questo momento attendo solo la conferma dal master per sapere se ha ricevuto tutto.
            m_waitingAckPeople = true;
            qInfo() << "[SLAVE] PEOPLE inviato in" << m_out.datagrams.size()
                    << "parti, totalSize=" << data_to_send.size();
            data_to_send.clear(); // il JSON completo non serve più
            // manteniamo però m_out.datagrams per eventuale ritrasmissione via NACK
        }
    });
    m_burstTimer.setInterval(1);
    m_burstTimer.start();
}
