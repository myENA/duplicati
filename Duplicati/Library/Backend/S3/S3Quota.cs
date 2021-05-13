using Duplicati.Library.Interface;
using Duplicati.Server.Serialization;
using System;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;

namespace Duplicati.Library.Backend
{
    public class QuotaResponse
    {
        public long Free { get; set; }
        public long Total { get; set; }
    }

    public partial class S3 : IQuotaEnabledBackend
    {
        /// <summary>
        /// The default listening port for local backup client (Duplicati standard port +1)
        /// </summary>
        public const int DEFAULT_LOCAL_API_PORT = 8200+1;

        private static readonly HttpClient client = new HttpClient
        {
            BaseAddress = new Uri("http://localhost:" + DEFAULT_LOCAL_API_PORT.ToString()),
        };

        public IQuotaInfo Quota
        {
            get
            {
                try
                {
                    // Add an Accept header for JSON format.
                    client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

                    // Call the quota-read endpoint
                    HttpResponseMessage response = client.GetAsync("/callback/quota-read").Result;
                    if (response.IsSuccessStatusCode)
                    {
                        // Parse the response body.
                        var data = Serializer.Deserialize<QuotaResponse>(new StringReader(response.Content.ReadAsStringAsync().Result));
                        return new QuotaInfo(data.Total, data.Free);
                    }
                    return null;
                }
                catch
                {
                    return null;
                }

            }
        }
    }
}
