// PeopleModel.cpp — Qt 5.12
#include "PeopleModel.h"
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonDocument>
#include <QCoreApplication>

PeopleModel::PeopleModel(QObject* parent)
    : QAbstractListModel(parent),
      m_settings(QSettings::IniFormat, QSettings::UserScope,
                 QCoreApplication::organizationName().isEmpty() ? "MyOrg" : QCoreApplication::organizationName(),
                 QCoreApplication::applicationName().isEmpty()   ? "MyApp" : QCoreApplication::applicationName())
{
    load();
}

int PeopleModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) return 0;
    return m_items.size();
}

QVariant PeopleModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return QVariant();

    const Person& p = m_items.at(index.row());
    switch (role) {
    case FirstNameRole: return p.firstName;
    case LastNameRole:  return p.lastName;
    case FullNameRole:  return fullNameOf(p.firstName, p.lastName);
    case InitialsRole:  return initialsOf(p.firstName, p.lastName);
    case PhotoRole:     return p.photo;
    default:            return QVariant();
    }
}

QHash<int, QByteArray> PeopleModel::roleNames() const
{
    return {
        { FirstNameRole, "firstName" },
        { LastNameRole,  "lastName"  },
        { FullNameRole,  "fullName"  },
        { InitialsRole,  "initials"  },
        { PhotoRole,     "photo"     }
    };
}

void PeopleModel::addPerson(const QString& firstName, const QString& lastName, const QString& photo)
{
    Person p{ firstName.trimmed(), lastName.trimmed(), photo };
    const int pos = m_items.size();
    beginInsertRows(QModelIndex(), pos, pos);
    m_items.push_back(std::move(p));
    endInsertRows();
    save();
}

void PeopleModel::removeAt(int row)
{
    if (row < 0 || row >= m_items.size()) return;
    beginRemoveRows(QModelIndex(), row, row);
    m_items.removeAt(row);
    endRemoveRows();
    save();
}

void PeopleModel::updateAt(int row, const QVariantMap& data)
{
    if (row < 0 || row >= m_items.size()) return;
    Person& p = m_items[row];

    if (data.contains("firstName")) p.firstName = data.value("firstName").toString().trimmed();
    if (data.contains("lastName"))  p.lastName  = data.value("lastName").toString().trimmed();
    if (data.contains("photo"))     p.photo     = data.value("photo").toString();

    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx, { FirstNameRole, LastNameRole, FullNameRole, InitialsRole, PhotoRole });
    save();
}

void PeopleModel::clearAll()
{
    if (m_items.isEmpty()) return;
    beginResetModel();
    m_items.clear();
    endResetModel();
    save();
}

int PeopleModel::indexOfByName(const QString& firstName, const QString& lastName) const
{
    for (int i = 0; i < m_items.size(); ++i) {
        if (m_items[i].firstName == firstName && m_items[i].lastName == lastName)
            return i;
    }
    return -1;
}

void PeopleModel::sortBy(const QString& field, bool ascending)
{
    if (m_items.size() <= 1) return;
    beginResetModel();
    std::sort(m_items.begin(), m_items.end(), [&](const Person& a, const Person& b){
        auto cmp = [&](const QString& x, const QString& y){
            const int r = QString::localeAwareCompare(x.toLower(), y.toLower());
            return ascending ? (r < 0) : (r > 0);
        };
        if (field == "firstName") return cmp(a.firstName, b.firstName);
        if (field == "lastName")  return cmp(a.lastName,  b.lastName);
        if (field == "fullName")  return cmp(fullNameOf(a.firstName, a.lastName),
                                             fullNameOf(b.firstName, b.lastName));
        // default: lastName poi firstName
        if (a.lastName != b.lastName) return cmp(a.lastName, b.lastName);
        return cmp(a.firstName, b.firstName);
    });
    endResetModel();
    save();
}

void PeopleModel::setPersist(bool p)
{
    if (m_persist == p) return;
    m_persist = p;
    emit persistChanged();
    if (m_persist) save();
}

void PeopleModel::save()
{
    if (!m_persist) return;

    QJsonArray arr;
    for (const auto& p : m_items) {
        QJsonObject o;
        o["firstName"] = p.firstName;
        o["lastName"]  = p.lastName;
        o["photo"]     = p.photo;
        arr.push_back(o);
    }
    const QJsonDocument doc(arr);
    m_settings.setValue(QStringLiteral("people/json"),
                        QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
    m_settings.sync();
}

QByteArray PeopleModel::toJson() const {
    QJsonArray arr;
    for (const auto& p : m_items) {
        QJsonObject o;
        o["firstName"] = p.firstName;
        o["lastName"]  = p.lastName;
        o["photo"]     = p.photo;
        arr.push_back(o);
    }
    QJsonObject root;
    root["type"] = "people";
    root["count"] = m_items.size();
    root["payload"] = arr;
    return QJsonDocument(root).toJson(QJsonDocument::Compact);
}

void PeopleModel::load()
{
    beginResetModel();
    m_items.clear();

    const QString json = m_settings.value(QStringLiteral("people/json")).toString();
    if (!json.isEmpty()) {
        const QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8());
        if (doc.isArray()) {
            const QJsonArray arr = doc.array();
            m_items.reserve(arr.size());
            for (const auto& v : arr) {
                const QJsonObject o = v.toObject();
                Person p;
                p.firstName = o.value("firstName").toString();
                p.lastName  = o.value("lastName").toString();
                p.photo     = o.value("photo").toString();
                m_items.push_back(std::move(p));
            }
        }
    }
    endResetModel();
}

QString PeopleModel::initialsOf(const QString& firstName, const QString& lastName)
{
    QString i;
    if (!firstName.isEmpty()) i += firstName.left(1).toUpper();
    if (!lastName.isEmpty())  i += lastName.left(1).toUpper();
    return i;
}

QString PeopleModel::fullNameOf(const QString& firstName, const QString& lastName)
{
    const QString fn = firstName.trimmed();
    const QString ln = lastName.trimmed();
    if (fn.isEmpty()) return ln;
    if (ln.isEmpty()) return fn;
    return fn + QStringLiteral(" ") + ln;
}
