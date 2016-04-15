using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data;
using System.Data.SqlClient;
using System.Xml.Serialization;
using System.Xml;
using System.IO;

namespace StackExchange.Opserver.SettingsProviders
{
    /// <summary>Generic XML serializer/deserializer with the ability to read objects from SQL queries that use FOR XML.</summary>
    public class SqlXmlHelper : IDisposable
    {
        private string dbs;
        private SqlConnection conn;

        /// <summary>Default constructor that does not initialze a database connection.</summary>
        public SqlXmlHelper()
        {
        }

        /// <summary>Initializes a SqlConnection with a connection string.</summary>
        /// <param name="dbstring">SQL Server connection string.</param>
        public SqlXmlHelper(string dbstring)
        {
            this.dbs = dbstring;
            this.conn = new SqlConnection(dbstring);
        }

        /// <summary>Initializes with a SqlConnection.  The connection supplied will not be used, but the ConnectionString propery will be used to create a new instance of SqlConnection.</summary>
        /// <param name="conn">SqlConnection instance to borrow the ConnectionString from.</param>
        public SqlXmlHelper(SqlConnection conn)
        {
            this.dbs = conn.ConnectionString;
            this.conn = new SqlConnection(this.dbs);
        }

        /// <summary>Gets or sets the connection string to use for database interactions.</summary>
        public string ConnectionString
        {
            get { return this.dbs; }
            set
            {
                this.dbs = value;
                this.conn = new SqlConnection(this.dbs);
            }
        }

        #region Database
        /// <summary>Queries the database specified by the ConnectionString property for XML to intialize an instance of T with.</summary>
        /// <typeparam name="T">The type to return.</typeparam>
        /// <param name="sql">A SQL query or stored procedure name.</param>
        /// <param name="cmdtype">The type of command supplied.</param>
        /// <param name="parameters">SqlParameters for the command to use.</param>
        /// <returns>An instance of T initialized with XML read from the FOR XML query.</returns>
        public T GetData<T>(string sql, CommandType cmdtype, params SqlParameter[] parameters) where T : new()
        {
            if (dbs == null || conn == null)
            {
                throw new ApplicationException("Data connection not yet initialized");
            }

            T obj = default(T);
            string xml = null;
            using (IDbCommand cmd = conn.CreateCommand())
            {
                cmd.CommandText = sql;
                cmd.CommandType = cmdtype;
                foreach (SqlParameter idp in parameters)
                {
                    cmd.Parameters.Add(idp);
                }
                if (!(conn.State == ConnectionState.Open))
                {
                    conn.Open();
                }
                using (IDataReader idr = cmd.ExecuteReader())
                {
                    if (idr.Read())
                    {
                        xml = idr[0].ToString();

                    }

                }
                conn.Close();

            }
            if (xml != null)
            {
                obj = Deserialize<T>(xml);
                return obj;
            }
            else
            {
                return new T();
            }

        }

        #region Deserialize
        /// <summary>Initializes an instance of T from XML read from an XML string.</summary>
        /// <typeparam name="T">The type to return.</typeparam>
        /// <param name="doc">XML string to initialize an instance of T with.</param>
        /// <returns>An instance of T initialized with the XML read from the XML string supplied.</returns>
        public T Deserialize<T>(string xml)
        {
            TextReader reader = new StringReader(xml);
            return Deserialize<T>(reader);
        }

        /// <summary>Initializes an instance of T from XML read from an XmlDocument.</summary>
        /// <typeparam name="T">The type to return.</typeparam>
        /// <param name="doc">XmlDocument holding XML to initialize an instance of T with.</param>
        /// <returns>An instance of T initialized with the XML read from the XmlDocument supplied.</returns>
        public T Deserialize<T>(XmlDocument doc)
        {
            TextReader reader = new StringReader(doc.OuterXml);
            return Deserialize<T>(reader);
        }

        /// <summary>Initializes an instance of T from XML read from a TextReader.</summary>
        /// <typeparam name="T">The type to return.</typeparam>
        /// <param name="reader">TextReader instance holding XML to initialize an instance of T with.</param>
        /// <returns>An instance of T initialized with the XML read from the TextReader supplied.</returns>
        public T Deserialize<T>(TextReader reader)
        {
            XmlSerializer s = new XmlSerializer(typeof(T));
            T o = (T)s.Deserialize(reader);
            reader.Close();
            return o;
        }
        #endregion

        #region Serialize
        /// <summary>Serializes an instance of T to an XmlDocument.</summary>
        /// <typeparam name="T">The type of the object to serialize.</typeparam>
        /// <param name="obj">Instance of T to serialize.</param>
        /// <returns>XmlDocument containing obj's instance data.</returns>
        public XmlDocument Serialize<T>(T obj)
        {
            string xml = StringSerialize<T>(obj);
            XmlDocument doc = new XmlDocument();
            doc.PreserveWhitespace = true;
            doc.LoadXml(xml);
            doc = Clean(doc);
            return doc;
        }

        private string StringSerialize<T>(T obj)
        {
            TextWriter w = WriterSerialize<T>(obj);
            string xml = w.ToString();
            w.Close();
            return xml.Trim();
        }

        private TextWriter WriterSerialize<T>(T obj)
        {
            TextWriter w = new StringWriter();
            XmlSerializer s = new XmlSerializer(typeof(T));
            s.Serialize(w, obj);
            w.Flush();
            return w;
        }
        #endregion

        #region XML Helper Methods
        // Removes XML namespaces added by the serializer.
        private XmlDocument Clean(XmlDocument doc)
        {
            doc.RemoveChild(doc.FirstChild);
            XmlNode first = doc.FirstChild;
            foreach (XmlNode n in doc.ChildNodes)
            {
                if (n.NodeType == XmlNodeType.Element)
                {
                    first = n;
                    break;
                }
            }
            if (first.Attributes != null)
            {
                XmlAttribute a = null;
                a = first.Attributes["xmlns:xsd"];
                if (a != null) { first.Attributes.Remove(a); }
                a = first.Attributes["xmlns:xsi"];
                if (a != null) { first.Attributes.Remove(a); }
            }
            return doc;
        }
        #endregion

        #region Static File Ops
        /// <summary>Reads object data from an XML file.</summary>
        /// <param name="file">XML file name.</param>
        /// <returns>T instance initialized from XML data in the file supplied.</returns>
        public static T ReadFile<T>(string file)
        {
            string xml = string.Empty;
            try
            {
                SqlXmlHelper serializer = new SqlXmlHelper();
                using (StreamReader reader = new StreamReader(file))
                {
                    xml = reader.ReadToEnd();
                }
                return serializer.Deserialize<T>(xml);
            }
            catch { }
            return default(T);
        }

        /// <summary>Writes object data to an XML file.</summary>
        /// <param name="file">XML file name.</param>
        /// <param name="config">Object to serialize.</param>
        /// <returns>Boolean success.</returns>
        public static bool WriteFile<T>(string file, T obj)
        {
            bool ok = false;
            SqlXmlHelper serializer = new SqlXmlHelper();
            try
            {
                string xml = serializer.Serialize(obj).OuterXml;
                using (StreamWriter writer = new StreamWriter(file, false))
                {
                    writer.Write(xml.Trim());
                    writer.Flush();

                }
                ok = true;
            }
            catch { }
            return ok;
        }
        #endregion

        /// <summary>Releases internal resources.</summary>
        public void Dispose()
        {
            if (conn != null)
            {
                if (conn.State != ConnectionState.Closed)
                {
                    conn.Close();
                }
                conn.Dispose();
                GC.SuppressFinalize(conn);
            }
        }
    }
}
#endregion