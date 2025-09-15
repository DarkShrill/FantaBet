#ifndef PEOPLEMODEL_H
#define PEOPLEMODEL_H


#include <QAbstractListModel>
#include <QVector>
#include <QJsonArray>
#include <QString>
#include <QSettings>

// Ogni persona candidata è rappresentata così: tengo anche la foto per comodità in UI.
struct Person {
    QString firstName;
    QString lastName;
    QString photo;   // path (file:///... o qrc:/...)
};

// Modello dei possibili giocatori: lo uso per popolare la schermata di scelta rapida.
class PeopleModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool persist READ persist WRITE setPersist NOTIFY persistChanged)

public:
    enum Roles {
        FirstNameRole = Qt::UserRole + 1,
        LastNameRole,
        FullNameRole,
        InitialsRole,
        PhotoRole
    };
    Q_ENUM(Roles)

    explicit PeopleModel(QObject* parent = nullptr);

    // QAbstractListModel
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // QML API
    // Aggiungo una nuova persona e salvo subito su disco se la persistenza è attiva.
    Q_INVOKABLE void addPerson(const QString& firstName,
                               const QString& lastName,
                               const QString& photo = QString());
    Q_INVOKABLE void removeAt(int row);
    // Posso aggiornare singole proprietà dalla UI senza ricreare la persona.
    Q_INVOKABLE void updateAt(int row, const QVariantMap& data);
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE int  indexOfByName(const QString& firstName, const QString& lastName) const;
    // Ordinamento personalizzabile: mi torna utile quando l'elenco cresce.
    Q_INVOKABLE void sortBy(const QString& field, bool ascending = true);
    Q_INVOKABLE QByteArray toJson() const;

    bool persist() const { return m_persist; }
    void setPersist(bool p);

signals:
    void persistChanged();

public slots:
    void save();
    void load();

private:
    static QString initialsOf(const QString& firstName, const QString& lastName);
    static QString fullNameOf(const QString& firstName, const QString& lastName);

    QVector<Person> m_items;
    // Flag per decidere al volo se salvare su disco: comodo durante i test.
    bool m_persist = true;

    // persistenza
    QSettings m_settings; // usa l’organizzazione/app del tuo progetto
};

#endif // PEOPLEMODEL_H
