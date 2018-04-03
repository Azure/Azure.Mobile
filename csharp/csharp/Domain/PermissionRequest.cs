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

		[JsonProperty("tokenDuration")]
		public int TokenDurationSeconds { get; set; }

		[JsonProperty("permissionMode")]
		public PermissionMode PermissionMode { get; set; }
	}
}
