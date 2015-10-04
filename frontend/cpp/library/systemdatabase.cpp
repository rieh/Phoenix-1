#include "systemdatabase.h"
#include "logging.h"

#include <QDir>
#include <QStandardPaths>
#include <QApplication>
#include <QSqlError>

using namespace Library;

QSqlDatabase SystemDatabase::database()
{
    return QSqlDatabase::database( QStringLiteral( "SYSTEMS" ) );
}

void SystemDatabase::close()
{
    if ( QSqlDatabase::contains( QStringLiteral( "SYSTEMS" ) ) ) {
        qDebug(phxLibrary) << "closing SYSTEM database";
        auto db = QSqlDatabase::database( QStringLiteral( "SYSTEMS" ) );
        db.close();
        QSqlDatabase::removeDatabase( QStringLiteral( "SYSTEMS" ) );
    }
}

void SystemDatabase::open()
{
    auto db = QSqlDatabase::addDatabase( QStringLiteral( "QSQLITE" ), QStringLiteral( "SYSTEMS" ) );

    QString dataPathStr = QStandardPaths::writableLocation( QStandardPaths::GenericDataLocation );
    Q_ASSERT( !dataPathStr.isEmpty() );

    QDir dataPath( dataPathStr );
    auto appname = QApplication::applicationName();

    if( !dataPath.exists( appname ) ) {
        dataPath.mkdir( appname ); // race...
    }

    Q_ASSERT( dataPath.cd( appname ) );

    auto databaseName = QStringLiteral("systems.db");
    auto filePath = dataPath.filePath( databaseName );

    db.setDatabaseName( filePath );
    if ( !db.open() ) {
        qCDebug( phxLibrary ) << "Could not open database SYSTEMS " << qPrintable( db.lastError().driverText() );
        return;
    }
    qCDebug( phxLibrary, "Opening library database %s", qPrintable( db.databaseName() ) );
}
