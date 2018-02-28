/**
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License.
 */

using System;

namespace csharp
{
    public static class EnvironmentVariables
    {
        static Uri _documentDbUri;

        public static Uri DocumentDbUri => _documentDbUri ?? (_documentDbUri = new Uri(DocumentDbUrl));

        public static readonly string DocumentDbUrl = Environment.GetEnvironmentVariable(RemoteDocumentDbUrl);

        public static readonly string DocumentDbKey = Environment.GetEnvironmentVariable(RemoteDocumentDbKey);

        public static readonly string StorageAccountConnection = Environment.GetEnvironmentVariable(AzureWebJobsStorage);

        public static readonly string NotificationHubName = Environment.GetEnvironmentVariable(AzureWebJobsNotificationHubName);

        public static readonly string NotificationHubConnectionString = Environment.GetEnvironmentVariable(AzureWebJobsNotificationHubsConnectionString);

        public static readonly string KeyVaultName = Environment.GetEnvironmentVariable(AzureKeyVaultName);

        public static readonly string KeyVaultUrl = Environment.GetEnvironmentVariable(AzureKeyVaultUrl);

        public const string AzureWebJobsStorage = nameof(AzureWebJobsStorage);

        public const string RemoteDocumentDbUrl = nameof(RemoteDocumentDbUrl);

        public const string RemoteDocumentDbKey = nameof(RemoteDocumentDbKey);

        public const string AzureWebJobsNotificationHubsConnectionString = nameof(AzureWebJobsNotificationHubsConnectionString);

        public const string AzureWebJobsNotificationHubName = nameof(AzureWebJobsNotificationHubName);

        public const string AzureKeyVaultName = nameof(AzureKeyVaultName);

        public const string AzureKeyVaultUrl = nameof(AzureKeyVaultUrl);
    }
}
