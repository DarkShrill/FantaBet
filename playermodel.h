#ifndef PLAYERMODEL_H
#define PLAYERMODEL_H


#include <QAbstractListModel>
#include <QColor>
#include <QString>
#include <QVector>

struct Player {
    uint32_t unique_id;
    QString firstName;
    QString lastName;
    QString avatar;   // qrc:/... oppure file:/...
    QColor  accentColor;
    double  accentHue = -1.0; // <0 = non impostata
};

class PlayerModel : public QAbstractListModel
{
    Q_OBJECT
    // Espone il count anche in QML
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    explicit PlayerModel(QObject* parent = nullptr);
    ~PlayerModel() override = default;

    // Ruoli del modello
    enum Roles {
        FirstNameRole = Qt::UserRole + 1,
        LastNameRole,
        FullNameRole,
        AvatarRole,
        AccentColorRole,
        AccentHueRole
    };
    Q_ENUM(Roles)

    // QAbstractItemModel overrides
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex& index, const QVariant& value, int role) override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;
    QHash<int, QByteArray> roleNames() const override;

    // API comode per QML
    Q_INVOKABLE int append(const QString& firstName,
                           const QString& lastName,
                           const QString& avatar = QString(),
                           const QVariant& accentColor = QVariant(),   // QColor o stringa #RRGGBB
                           const QVariant& accentHue = QVariant());    // double 0..1
    Q_INVOKABLE int appendMimimal(const QString& firstName,
                           const QString& lastName,
                           const QString& avatar = QString(), int unique_id = 0);    // double 0..1
    Q_INVOKABLE void clear();
    Q_INVOKABLE bool removeAt(int row);
    Q_INVOKABLE bool setAccentColor(int row, const QVariant& color);   // QColor o stringa
    Q_INVOKABLE bool setAccentHue(int row, double hue01);              // 0..1


    Player * getPlayerFromUniqueId(int who);
signals:
    void countChanged();

private:


    QColor colorFromHue(double hue01) const;
    QColor autoColorForIndex(int row) const;

    QVector<Player> m_items;
};

#endif // PLAYERMODEL_H
