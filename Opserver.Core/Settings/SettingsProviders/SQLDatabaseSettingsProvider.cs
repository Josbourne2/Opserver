using System;
using System.Collections.Concurrent;
using System.IO;
using System.Xml.Serialization;
using System.Data;
using System.Data.SqlClient;
using System.Xml;

namespace StackExchange.Opserver.SettingsProviders
{


    public class SQLDatabaseSettingsProvider : SettingsProvider
    {
        private string dbs;
        private SqlConnection conn;
        private SqlXmlHelper xmlHelper;

        private readonly object _loadLock = new object();
        private readonly ConcurrentDictionary<Type, object> _settingsCache = new ConcurrentDictionary<Type, object>();

        public override string ProviderType => "SQLDatabase";

        public SQLDatabaseSettingsProvider(SettingsSection settings) : base(settings)
        {
            this.dbs = settings.ConnectionString;

            this.conn = new SqlConnection(dbs);
            xmlHelper = new SqlXmlHelper(conn);

        }

        public override T GetSettings<T>()
        {
            object cached;
            //if (_settingsCache.TryGetValue(typeof(T), out cached))
            //    return (T)cached;

            lock (_loadLock)
            {
                //if (_settingsCache.TryGetValue(typeof(T), out cached))
                //    return (T)cached;
                string settingsName = GetSettingsName<T>();
                var settings = xmlHelper.GetData<T>("Mon_GetOpmanagerSettings", CommandType.StoredProcedure, new SqlParameter("@settingsName", settingsName));
                if (settings == null)
                    return null;
                _settingsCache.TryAdd(typeof(T), settings);
                return settings;
            }



        }

        private string GetSettingsName<T>()
        {
            return typeof(T).Name;
        }



        public override T SaveSettings<T>(T settings)
        {
            return settings;
        }



    }
}
