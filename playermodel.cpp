#include "playermodel.h"
#include <QtMath>

PlayerModel::PlayerModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

int PlayerModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) return 0;
    return m_items.size();
}

QVariant PlayerModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const Player& p = m_items.at(index.row());

    switch (role) {
    case FirstNameRole:  return p.firstName;
    case LastNameRole:   return p.lastName;
    case FullNameRole: {
        const QString full = (p.firstName + QStringLiteral(" ") + p.lastName).trimmed();
        return full;
    }
    case AvatarRole:     return p.avatar;
    case AccentColorRole: {
        // Se non c'è accentColor ma c'è hue, calcola al volo
        QColor c = p.accentColor.isValid()
                   ? p.accentColor
                   : (p.accentHue >= 0.0 ? colorFromHue(p.accentHue)
                                         : autoColorForIndex(index.row()));
        return c;
    }
    case AccentHueRole:  return (p.accentHue >= 0.0 ? p.accentHue : QVariant());
    default:             return {};
    }
}

bool PlayerModel::setData(const QModelIndex& index, const QVariant& value, int role)
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return false;

    Player& p = m_items[index.row()];
    bool changed = false;

    switch (role) {
    case FirstNameRole:
        if (p.firstName != value.toString()) { p.firstName = value.toString(); changed = true; }
        break;
    case LastNameRole:
        if (p.lastName != value.toString()) { p.lastName = value.toString(); changed = true; }
        break;
    case AvatarRole:
        if (p.avatar != value.toString()) { p.avatar = value.toString(); changed = true; }
        break;
    case AccentColorRole: {
        QColor c = value.canConvert<QColor>() ? value.value<QColor>() : QColor(value.toString());
        if (c.isValid() && c != p.accentColor) { p.accentColor = c; changed = true; }
        break;
    }
    case AccentHueRole: {
        bool ok = false;
        double h = value.toDouble(&ok);
        if (ok) {
            if (h < 0.0) h = 0.0;
            if (h > 1.0) h = std::fmod(h, 1.0);
            if (!qFuzzyCompare(p.accentHue, h)) { p.accentHue = h; changed = true; }
        }
        break;
    }
    default:
        break;
    }

    if (changed) {
        emit dataChanged(index, index, { role });
        if (role == FirstNameRole || role == LastNameRole)
            emit dataChanged(index, index, { FullNameRole });
    }
    return changed;
}

Qt::ItemFlags PlayerModel::flags(const QModelIndex& index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsEditable;
}

QHash<int, QByteArray> PlayerModel::roleNames() const
{
    return {
        { FirstNameRole,   "firstName"   },
        { LastNameRole,    "lastName"    },
        { FullNameRole,    "fullName"    },
        { AvatarRole,      "avatar"      },
        { AccentColorRole, "accentColor" },
        { AccentHueRole,   "accentHue"   }
    };
}

int PlayerModel::append(const QString& firstName,
                        const QString& lastName,
                        const QString& avatar,
                        const QVariant& accentColorVar,
                        const QVariant& accentHueVar)
{
    Player p;
    p.firstName = firstName;
    p.lastName  = lastName;
    p.avatar    = avatar;

    if (accentHueVar.isValid()) {
        bool ok = false;
        double h = accentHueVar.toDouble(&ok);
        if (ok) {
            if (h < 0.0) h = 0.0;
            if (h > 1.0) h = std::fmod(h, 1.0);
            p.accentHue = h;
        }
    }

    if (accentColorVar.isValid()) {
        QColor c = accentColorVar.canConvert<QColor>() ? accentColorVar.value<QColor>()
                                                       : QColor(accentColorVar.toString());
        if (c.isValid())
            p.accentColor = c;
    }

    const int row = m_items.size();
    beginInsertRows(QModelIndex(), row, row);
    m_items.push_back(p);
    endInsertRows();
    emit countChanged();
    return row;
}

int PlayerModel::appendMimimal(const QString &firstName, const QString &lastName, const QString &avatar, int unique_id)
{
    const QVariant accentColorVar;
    const QVariant accentHueVar = m_items.count() == 0 ? 0.0 : (m_items.count())*0.12;
    Player p;
    p.unique_id = unique_id;
    p.firstName = firstName;
    p.lastName  = lastName;
    p.avatar    = avatar;

    if (accentHueVar.isValid()) {
        bool ok = false;
        double h = accentHueVar.toDouble(&ok);
        if (ok) {
            if (h < 0.0) h = 0.0;
            if (h > 1.0) h = std::fmod(h, 1.0);
            p.accentHue = h;
        }
    }

    if (accentColorVar.isValid()) {
        QColor c = accentColorVar.canConvert<QColor>() ? accentColorVar.value<QColor>()
                                                       : QColor(accentColorVar.toString());
        if (c.isValid())
            p.accentColor = c;
    }

    const int row = m_items.size();
    beginInsertRows(QModelIndex(), row, row);
    m_items.push_back(p);
    endInsertRows();
    emit countChanged();
    return row;
}

void PlayerModel::clear()
{
    if (m_items.isEmpty()) return;
    beginResetModel();
    m_items.clear();
    endResetModel();
    emit countChanged();
}

bool PlayerModel::removeAt(int row)
{
    if (row < 0 || row >= m_items.size()) return false;
    beginRemoveRows(QModelIndex(), row, row);
    m_items.removeAt(row);
    endRemoveRows();
    emit countChanged();
    return true;
}

bool PlayerModel::setAccentColor(int row, const QVariant& color)
{
    if (row < 0 || row >= m_items.size()) return false;
    QColor c = color.canConvert<QColor>() ? color.value<QColor>() : QColor(color.toString());
    if (!c.isValid()) return false;
    m_items[row].accentColor = c;
    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx, { AccentColorRole });
    return true;
}

bool PlayerModel::setAccentHue(int row, double hue01)
{
    if (row < 0 || row >= m_items.size()) return false;
    if (hue01 < 0.0) hue01 = 0.0;
    if (hue01 > 1.0) hue01 = std::fmod(hue01, 1.0);
    m_items[row].accentHue = hue01;
    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx, { AccentHueRole, AccentColorRole });
    return true;
}

Player *PlayerModel::getPlayerFromUniqueId(int who)
{
    for (Player &p : m_items) {
        if (p.unique_id == who)
            return &p;
    }
    return nullptr;
}

QColor PlayerModel::colorFromHue(double h) const
{
    // Saturation 0.6, Lightness 0.5, Alpha 1.0 come nel tuo QML
    QColor c;
    c.setHslF(h, 0.6, 0.5, 1.0);
    return c;
}

QColor PlayerModel::autoColorForIndex(int row) const
{
    // Sequenza “distinta”: hue = (row * 0.12) % 1.0
    double h = std::fmod(static_cast<double>(row) * 0.12, 1.0);
    return colorFromHue(h);
}
