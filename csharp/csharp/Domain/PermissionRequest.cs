/**
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License.
 */

using Microsoft.Azure.Documents;

using Newtonsoft.Json;

namespace csharp
{
    public class PermissionRequest
    {
        [JsonProperty("databaseId")]
        public string DatabaseId { get; set; }

        [JsonProperty("collectionId")]
        public string CollectionId { get; set; }

        [JsonProperty("resourceLink")]
        public string ResourceLink { get; set; }

        [JsonProperty("tokenDuration")]
        public int TokenDurationSeconds { get; set; }

        [JsonProperty("permissionMode")]
        public PermissionMode PermissionMode { get; set; }
    }
}
