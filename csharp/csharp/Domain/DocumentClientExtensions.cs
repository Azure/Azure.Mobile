/**
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License.
 */

using System;
using System.Collections.Generic;
using System.Threading.Tasks;

using Microsoft.Azure.Documents;
using Microsoft.Azure.Documents.Client;
using Microsoft.Azure.WebJobs.Host;

using HttpStatusCode = System.Net.HttpStatusCode;

namespace csharp
{
    public static class DocumentClientExtensions
    {

        static RequestOptions PermissionRequestOptions(int durationInSeconds) => new RequestOptions { ResourceTokenExpirySeconds = durationInSeconds };

        static string GetUserPermissionId(string databaseId, string userId, PermissionMode permissionMode) => $"{databaseId}-{userId}-{permissionMode.ToString().ToUpper()}";


        public static async Task<Permission> GetOrCreatePermission(this DocumentClient client, (string DatabaseId, string CollectionId) collection, string userId, PermissionMode permissionMode, int durationInSeconds, TraceWriter log)
        {
            var permissionId = string.Empty;

            try
            {
                await client.EnsureCollection(collection, log);

                log?.Info($" ... getting collection ({collection.CollectionId}) in database ({collection.DatabaseId})");

                var collectionResponse = await client.ReadDocumentCollectionAsync(UriFactory.CreateDocumentCollectionUri(collection.DatabaseId, collection.CollectionId));

                var documentCollection = collectionResponse?.Resource ?? throw new Exception($"Could not find Document Collection in Database {collection.DatabaseId} with CollectionId: {collection.CollectionId}");


                var userTup = await client.GetOrCreateUser(collection.DatabaseId, userId, log);

                var user = userTup.user;

                Permission permission;

                permissionId = GetUserPermissionId(collection.DatabaseId, user.Id, permissionMode);

                // if the user was newly created, go ahead and create the permission
                if (userTup.created && !string.IsNullOrEmpty(user?.Id))
                {
                    permission = await client.CreateNewPermission(collection.DatabaseId, documentCollection, user, permissionId, permissionMode, durationInSeconds, log);
                }
                else // else look for an existing permission with the id
                {
                    var permissionUri = UriFactory.CreatePermissionUri(collection.DatabaseId, user.Id, permissionId);

                    try
                    {
                        log?.Info($" ... getting permission ({permissionId}) at uri: {permissionUri}");

                        var permissionResponse = await client.ReadPermissionAsync(permissionUri, PermissionRequestOptions(durationInSeconds));

                        permission = permissionResponse?.Resource;

                        if (permission != null)
                        {
                            log?.Info($" ... found existing permission ({permission.Id})");
                        }
                    }
                    catch (DocumentClientException dcx)
                    {
                        dcx.Print(log);

                        switch (dcx.StatusCode)
                        {
                            case HttpStatusCode.NotFound:

                                log?.Info($" ... could not find permission ({permissionId}) at uri: {permissionUri} - creating...");

                                permission = await client.CreateNewPermission(collection.DatabaseId, documentCollection, user, permissionId, permissionMode, durationInSeconds, log);

                                break;

                            default: throw;
                        }
                    }
                }

                return permission;
            }
            catch (Exception ex)
            {
                log?.Error($"Error creating new new {permissionMode.ToString().ToUpper()} Permission [Database: {collection.DatabaseId} Collection: {collection.CollectionId}  User: {userId}  Permission: {permissionId}", ex);
                throw;
            }
        }



        static async Task<Permission> CreateNewPermission(this DocumentClient client, string databaseId, DocumentCollection collection, User user, string permissionId, PermissionMode permissionMode, int durationInSeconds, TraceWriter log)
        {
            log?.Info($" ... creating new permission ({permissionId}) for collection ({collection?.Id})");

            var newPermission = new Permission { Id = permissionId, ResourceLink = collection.SelfLink, PermissionMode = permissionMode };

            try
            {
                var permissionResponse = await client.CreatePermissionAsync(user.SelfLink, newPermission, PermissionRequestOptions(durationInSeconds));

                var permission = permissionResponse?.Resource;

                if (permission != null)
                {
                    log?.Info($" ... created new permission ({permission.Id})");
                }

                return permission;
            }
            catch (DocumentClientException dcx)
            {
                dcx.Print(log);

                switch (dcx.StatusCode)
                {
                    case HttpStatusCode.Conflict:

                        var oldPermissionId = permissionId.Replace(permissionMode.ToString().ToUpper(), permissionMode == PermissionMode.All ? PermissionMode.Read.ToString().ToUpper() : PermissionMode.All.ToString().ToUpper());

                        log?.Info($" ... deleting old permission ({oldPermissionId})");

                        await client.DeletePermissionAsync(UriFactory.CreatePermissionUri(databaseId, user.Id, oldPermissionId));

                        log?.Info($" ... creating new permission ({permissionId}) for collection ({collection?.Id})");

                        var permissionResponse = await client.CreatePermissionAsync(user.SelfLink, newPermission, PermissionRequestOptions(durationInSeconds));

                        var permission = permissionResponse?.Resource;

                        if (permission != null)
                        {
                            log?.Info($" ... created new permission ({permission.Id})");
                        }

                        return permission;

                    default: throw;
                }
            }
            catch (Exception ex)
            {
                log?.Error($"Error creating new Permission with Id: {permissionId}  for Collection: {collection?.Id}", ex);
                throw;
            }
        }


        static async Task<(User user, bool created)> GetOrCreateUser(this DocumentClient client, string databaseId, string userId, TraceWriter log)
        {
            User user = null;

            try
            {
                log?.Info($" ... getting user ({userId}) in database ({databaseId})");

                var response = await client.ReadUserAsync(UriFactory.CreateUserUri(databaseId, userId));

                user = response?.Resource;

                if (user != null)
                {
                    log?.Info($" ... found existing user ({userId}) in database ({databaseId})");
                }

                return (user, false);
            }
            catch (DocumentClientException dcx)
            {
                dcx.Print(log);

                switch (dcx.StatusCode)
                {
                    case HttpStatusCode.NotFound:

                        log?.Info($" ... did not find user ({userId}) - creating...");

                        var response = await client.CreateUserAsync(UriFactory.CreateDatabaseUri(databaseId), new User { Id = userId });

                        user = response?.Resource;

                        if (user != null)
                        {
                            log?.Info($" ... created new user ({userId}) in database ({databaseId})");
                        }

                        return (user, user != null);

                    default: throw;
                }
            }
            catch (Exception ex)
            {
                log?.Error($"Error getting User with Id: {userId}\n", ex);
                throw;
            }
        }


        public static void Print(this DocumentClientException dex, TraceWriter log)
        {
            if ((int)dex.StatusCode == 429)
            {
                log?.Info("TooManyRequests - This means you have exceeded the number of request units per second. Consult the DocumentClientException.RetryAfter value to see how long you should wait before retrying this operation.");
            }
            else
            {
                switch (dex.StatusCode)
                {
                    case HttpStatusCode.BadRequest:
                        log?.Info("BadRequest - This means something was wrong with the document supplied. It is likely that disableAutomaticIdGeneration was true and an id was not supplied");
                        break;
                    case HttpStatusCode.Forbidden:
                        log?.Info("Forbidden - This likely means the collection in to which you were trying to create the document is full.");
                        break;
                    case HttpStatusCode.Conflict:
                        log?.Info("Conflict - This means a Document with an id matching the id field of document already existed");
                        break;
                    case HttpStatusCode.RequestEntityTooLarge:
                        log?.Info("RequestEntityTooLarge - This means the Document exceeds the current max entity size. Consult documentation for limits and quotas.");
                        break;
                    default:
                        break;
                }
            }
        }


        #region Initialization (database & collections)

        static readonly Dictionary<string, ClientStatus> _databaseStatuses = new Dictionary<string, ClientStatus>();

        static readonly Dictionary<string, Task<ResourceResponse<Database>>> _databaseCreationTasks = new Dictionary<string, Task<ResourceResponse<Database>>>();


        static readonly Dictionary<(string DatabaseId, string CollectionId), ClientStatus> _collectionStatuses = new Dictionary<(string DatabaseId, string CollectionId), ClientStatus>();

        static readonly Dictionary<(string DatabaseId, string CollectionId), Task<ResourceResponse<DocumentCollection>>> _collectionCreationTasks = new Dictionary<(string DatabaseId, string CollectionId), Task<ResourceResponse<DocumentCollection>>>();


        static bool IsInitialized((string DatabaseId, string CollectionId) collection) => _collectionStatuses.TryGetValue(collection, out ClientStatus status) && status == ClientStatus.Initialized;


        static async Task EnsureCollection(this DocumentClient client, (string DatabaseId, string CollectionId) collection, TraceWriter log)
        {
            if (!(IsInitialized(collection) || await client.InitializeCollection(collection, log)))
            {
                throw new Exception($"Could not find Document Collection in Database {collection.DatabaseId} with CollectionId: {collection.CollectionId}");
            }
        }


        static async Task<bool> InitializeCollection(this DocumentClient client, (string DatabaseId, string CollectionId) collection, TraceWriter log)
        {
            if (!(_databaseStatuses.TryGetValue(collection.DatabaseId, out ClientStatus databaseStatus) && databaseStatus == ClientStatus.Initialized))
            {
                await client.CreateDatabaseIfNotExistsAsync(collection.DatabaseId, log);
            }

            if (!IsInitialized(collection))
            {
                await client.CreateCollectionIfNotExistsAsync(collection, log);
            }

            return IsInitialized(collection);
        }


        static async Task CreateDatabaseIfNotExistsAsync(this DocumentClient client, string databaseId, TraceWriter log)
        {
            if (_databaseCreationTasks.TryGetValue(databaseId, out Task<ResourceResponse<Database>> task) && !task.IsNullFinishCanceledOrFaulted())
            {
                log?.Info($" ... database ({databaseId}) is already being created, returning existing task");

                await task;
            }
            else
            {
                try
                {
                    log?.Info($" ... checking for database ({databaseId})");

                    _databaseCreationTasks[databaseId] = client.ReadDatabaseAsync(UriFactory.CreateDatabaseUri(databaseId));

                    var database = await _databaseCreationTasks[databaseId];

                    if (database?.Resource != null)
                    {
                        _databaseStatuses[databaseId] = ClientStatus.Initialized;

                        log?.Info($" ... found existing database ({databaseId})");
                    }
                }
                catch (DocumentClientException dex)
                {
                    switch (dex.StatusCode)
                    {
                        case HttpStatusCode.NotFound:

                            _databaseCreationTasks[databaseId] = client.CreateDatabaseAsync(new Database { Id = databaseId });

                            var database = await _databaseCreationTasks[databaseId];

                            if (database?.Resource != null)
                            {
                                _databaseStatuses[databaseId] = ClientStatus.Initialized;

                                log?.Info($" ... created new database ({databaseId})");
                            }

                            break;

                        default: throw;
                    }
                }
                catch (Exception ex)
                {
                    _databaseStatuses[databaseId] = ClientStatus.NotInitialized;

                    log?.Error(ex.Message, ex);

                    throw;
                }
            }
        }


        static async Task CreateCollectionIfNotExistsAsync<T>(this DocumentClient client, string databaseId, TraceWriter log)
        {
            await client.CreateCollectionIfNotExistsAsync((databaseId, typeof(T).Name), log);
        }


        static async Task CreateCollectionIfNotExistsAsync(this DocumentClient client, (string DatabaseId, string CollectionId) collection, TraceWriter log)
        {
            if (_collectionCreationTasks.TryGetValue(collection, out Task<ResourceResponse<DocumentCollection>> task) && !task.IsNullFinishCanceledOrFaulted())
            {
                log?.Info($" ... collection ({collection.CollectionId}) in database ({collection.DatabaseId}) is already being created, returning existing task");

                await task;
            }
            else
            {
                try
                {
                    log?.Info($" ... checking for collection ({collection.CollectionId}) in database ({collection.DatabaseId})");

                    _collectionCreationTasks[collection] = client.ReadDocumentCollectionAsync(UriFactory.CreateDocumentCollectionUri(collection.DatabaseId, collection.CollectionId));

                    var collectionResponse = await _collectionCreationTasks[collection];

                    if (collectionResponse?.Resource != null)
                    {
                        _collectionStatuses[collection] = ClientStatus.Initialized;

                        log?.Info($" ... found existing collection ({collection.CollectionId}) in database ({collection.DatabaseId})");
                    }
                }
                catch (DocumentClientException dex)
                {
                    switch (dex.StatusCode)
                    {
                        case HttpStatusCode.NotFound:

                            _collectionCreationTasks[collection] = client.CreateDocumentCollectionAsync(UriFactory.CreateDatabaseUri(collection.DatabaseId), new DocumentCollection { Id = collection.CollectionId }, new RequestOptions { OfferThroughput = 1000 });

                            var collectionResponse = await _collectionCreationTasks[collection];

                            if (collectionResponse?.Resource != null)
                            {
                                _collectionStatuses[collection] = ClientStatus.Initialized;

                                log?.Info($" ... created new collection ({collection.CollectionId}) in database ({collection.DatabaseId})");
                            }

                            break;

                        default: throw;
                    }
                }
                catch (Exception ex)
                {
                    _collectionStatuses[collection] = ClientStatus.NotInitialized;

                    log?.Error(ex.Message, ex);

                    throw;
                }
            }
        }

        #endregion
    }

    public enum ClientStatus
    {
        NotInitialized,
        Initializing,
        Initialized
    }
}
