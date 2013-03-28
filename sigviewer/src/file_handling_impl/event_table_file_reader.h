/*

    $Id$
    Copyright (C) Christoph Eibel 2010 
    Copyright (C) Alois Schloegl  2011
		and others ???
    This file is part of the "SigViewer" repository 
    at http://biosig.sf.net/ 

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 3
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>. 
    
*/

// event_table_file_reader.h

#ifndef EVENT_TABLE_FILE_READER
#define EVENT_TABLE_FILE_READER

#include "base/sigviewer_user_types.h"
#include "biosig.h"

#include <QStringList>
#include <QMap>
#include <QList>

#include <set>


class QTextStream;

namespace SigViewer_
{


//-----------------------------------------------------------------------------
///
/// EventTableFileReader
///
/// responsible for mapping of EventType to String (name of event)
class EventTableFileReader
{
public:
    typedef QList<uint16>::const_iterator IntIterator;
    typedef QStringList::const_iterator StringIterator;

    EventTableFileReader();
    ~EventTableFileReader();

    StringIterator getGroupIdBegin() const;
    StringIterator getGroupIdEnd() const;
    QString getEventGroupName(const QString& group_id) const;

    IntIterator eventTypesBegin();
    IntIterator eventTypesEnd();
    QString getEventName (EventType event_type_id) const;
    void setEventName (EventType event_type_id, QString const& name);
    void restoreEventNames ();
    std::set<EventType> getEventsOfGroup (QString const& group_id) const;
    QString getEventGroupId (EventType event_type_id) const;

    //---------------------------------------------------------------------------------------------
    /// @return true if an the eventtablefilereader has an entry of this type;
    ///         false if not
    bool entryExists (EventType type) const;

    //---------------------------------------------------------------------------------------------
    void addEntry (EventType type, QString const& name = "", QString group_id = "");

    std::set<uint16> getAllEventTypes () const;
private:
    bool load();
    static QString const UNKNOWN_GROUP_ID;

    struct EventItem
    {
        QString name;
        QString group_id;
    };

    typedef QMap<EventType, EventItem> Int2EventItemMap;
    typedef QMap<QString, QString> String2StringMap;

    Q_DISABLE_COPY(EventTableFileReader)

    QList<EventType> event_types_;
    Int2EventItemMap event_type2name_;

    QStringList event_group_ids_;
    String2StringMap group_id2name_;

};

} // namespace SigViewer_

#endif
