/**
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License.
 */

using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

using Microsoft.Azure.Documents;
using Microsoft.Azure.Documents.Client;
using Microsoft.Azure.KeyVault;
using Microsoft.Azure.KeyVault.Models;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Host;

using Newtonsoft.Json;

namespace csharp
{
    public static class GetResourcePermission
    {

		const string AnonymousId = "anonymous-user";

		const int MaxTokenDurationSeconds = 18000; // 5 hours
		const double TokenRefreshSeconds = 600; // 10 minutes


		static DocumentClient _documentClient;
		static DocumentClient DocumentClient => _documentClient ?? (_documentClient = new DocumentClient(EnvironmentVariables.DocumentDbUri, EnvironmentVariables.DocumentDbKey));

		static AzureServiceTokenProvider _azureServiceTokenProvider;
		static AzureServiceTokenProvider AzureServiceTokenProvider => _azureServiceTokenProvider ?? (_azureServiceTokenProvider = new AzureServiceTokenProvider());

		static KeyVaultClient _keyVaultClient;
		static KeyVaultClient KeyVaultClient => _keyVaultClient ?? (_keyVaultClient = new KeyVaultClient(new KeyVaultClient.AuthenticationCallback(AzureServiceTokenProvider.KeyVaultTokenCallback)));


		[Authorize]
        [FunctionName(nameof(GetResourcePermission))]
        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "api/data/permission")]HttpRequest req, TraceWriter log)
        {
			try
			{
				string body = null;
				SecretBundle secretBundle = null;
				PermissionRequest permissionRequest = null;

				var userId = Thread.CurrentPrincipal.GetClaimsIdentity()?.UniqueIdentifier() ?? AnonymousId;

				log.Info($" ... userId: {userId}");


				using (var reader = new StreamReader(req.Body))
				{
					body = reader.ReadToEnd();
				}

				if (!string.IsNullOrEmpty(body))
				{
					permissionRequest = JsonConvert.DeserializeObject<PermissionRequest>(body);
				}


				if (string.IsNullOrEmpty(permissionRequest?.DatabaseId))
				{
					return new StatusCodeResult(StatusCodes.Status400BadRequest);
				}

				var tokenDurationSeconds = permissionRequest.TokenDurationSeconds < (TokenRefreshSeconds * 2) ? (TokenRefreshSeconds * 2) 
										 : permissionRequest.TokenDurationSeconds > MaxTokenDurationSeconds ? MaxTokenDurationSeconds
										 : permissionRequest.TokenDurationSeconds;


				var secretId = GetSecretName(permissionRequest.DatabaseId, permissionRequest.CollectionId, userId);

				log.Info($" ... secretId: {secretId} ({secretId.Length})");


				try
				{
					secretBundle = await KeyVaultClient.GetSecretAsync(EnvironmentVariables.KeyVaultUrl, secretId);
				}
				catch (KeyVaultErrorException kvex)
				{
					if (kvex.Body.Error.Code != "SecretNotFound")
					{
						throw;
					}

					log.Info($" ... existing secret not found");
				}


				// if the token is still valid for longer than TokenRefreshSeconds, return it
				if (secretBundle != null && secretBundle.Attributes.Expires.HasValue
					&& secretBundle.Attributes.Expires.Value.Subtract(DateTime.UtcNow).TotalSeconds > TokenRefreshSeconds)
				{
					log.Info($" ... existing secret found with greater than {TokenRefreshSeconds} seconds remaining before expiration");

					//JsonConvert.DeserializeObject<Permission>(secretBundle.Value);

					return new OkObjectResult(secretBundle.Value);
				}


				log.Info($" ... getting new permission token for user");

				// simply getting the user permission will refresh the token
				var userPermission = await DocumentClient.GetOrCreatePermission(permissionRequest.DatabaseId, permissionRequest.CollectionId, userId, permissionRequest.PermissionMode, (int)tokenDurationSeconds, log);


				if (!string.IsNullOrEmpty(userPermission?.Token))
				{
					log.Info($" ... saving new permission token to key vault");

					var permissionJson = JsonConvert.SerializeObject(userPermission);

					secretBundle = await KeyVaultClient.SetSecretAsync(EnvironmentVariables.KeyVaultUrl, secretId, permissionJson, secretAttributes: new SecretAttributes(expires: DateTime.UtcNow.AddSeconds(tokenDurationSeconds)));

					return new OkObjectResult(secretBundle.Value);
				}


				log.Info($" ... failed to get new permission token for user");

				return new StatusCodeResult(500);
			}
			catch (Exception ex)
			{
				log.Error(ex.Message, ex);

				return new StatusCodeResult(500);
			}
		}


		// The name must be a string 1-127 characters in length containing only 0-9, a-z, A-Z, and -.
		// example userId: google|sid:uir7d29343a3gufe414098b063199430
		static string GetSecretName(string databaseId, string collectionId, string userId)
		{
			const char pipe = '|', colon = ':', hyphen = '-', underscore = '_';

			var normalizedUserId = userId.Replace(pipe, hyphen)
										 .Replace(colon, hyphen)
										 .Replace(underscore, hyphen);

			var collectionSegment = string.IsNullOrEmpty(collectionId) ? "" : $"-{collectionId}";

			return $"{databaseId}{collectionSegment}-{normalizedUserId}";
		}
	}
}
