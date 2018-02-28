/**
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License.
 */

using System;

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


namespace csharp
{
    public static class GetDataToken
    {
        const string AnonymousId = "anonymous-user";

        const int TokenDurationSeconds = 18000; // 5 hours
        const double TokenRefreshSeconds = 600; // 10 minutes


        static DocumentClient _documentClient;
        static DocumentClient DocumentClient => _documentClient ?? (_documentClient = new DocumentClient(EnvironmentVariables.DocumentDbUri, EnvironmentVariables.DocumentDbKey));

        static AzureServiceTokenProvider _azureServiceTokenProvider;
        static AzureServiceTokenProvider AzureServiceTokenProvider => _azureServiceTokenProvider ?? (_azureServiceTokenProvider = new AzureServiceTokenProvider());

        static KeyVaultClient _keyVaultClient;
        static KeyVaultClient KeyVaultClient => _keyVaultClient ?? (_keyVaultClient = new KeyVaultClient(new KeyVaultClient.AuthenticationCallback(AzureServiceTokenProvider.KeyVaultTokenCallback)));


        [Authorize]
        [FunctionName(nameof(GetDataToken))]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "api/data/{databaseId}/{collectionId}/token")]
            HttpRequest req, string databaseId, string collectionId, TraceWriter log)
        {
            try
            {
                SecretBundle secretBundle = null;

                var userId = Thread.CurrentPrincipal.GetClaimsIdentity()?.UniqueIdentifier() ?? AnonymousId;

                log.Info($" ... userId: {userId}");


                var secretId = GetSecretName(databaseId, collectionId, userId);

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

                    return new OkObjectResult(secretBundle.Value);
                }


                log.Info($" ... getting new permission token for user");

                // simply getting the user permission will refresh the token
                var userPermission = await DocumentClient.GetOrCreatePermission((databaseId, collectionId), userId, PermissionMode.All, TokenDurationSeconds, log);


                if (!string.IsNullOrEmpty(userPermission?.Token))
                {
                    log.Info($" ... saving new permission token to key vault");

                    secretBundle = await KeyVaultClient.SetSecretAsync(EnvironmentVariables.KeyVaultUrl, secretId, userPermission.Token, secretAttributes: new SecretAttributes(expires: DateTime.UtcNow.AddSeconds(TokenDurationSeconds)));

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

            return $"{databaseId}-{collectionId}-{normalizedUserId}";
        }
    }
}
