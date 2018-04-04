/**
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License.
 */

using System;
using System.Linq;
using System.Net.Http;
using System.Security.Claims;
using System.Security.Principal;
using Microsoft.AspNetCore.Http;

namespace csharp
{
    public static class SecurityExtensions
    {
        const string zumoAuthHeaderKey = "x-zumo-auth";
        const string xmsClientPrincipalNameKey = "X-MS-CLIENT-PRINCIPAL-NAME";
        const string xmsClientPrincipalIdKey = "X-MS-CLIENT-PRINCIPAL-ID";
        const string xmsClientPrincipalProviderKey = "X-MS-CLIENT-PRINCIPAL-IDP";
        const string JwtRegisteredClaimNamesIss = "iss";

        // https://github.com/Azure/azure-mobile-apps-net-server/wiki/Understanding-User-Ids
        public static string UniqueIdentifier(this IPrincipal user)
        {
            if (user is ClaimsPrincipal principal)
            {
                if (principal.Identity is ClaimsIdentity identity)
                {
                    return identity.UniqueIdentifier();
                }
            }

            return null;
        }


        public static string UniqueIdentifier(this ClaimsIdentity identity)
        {
            if (identity != null)
            {
                var stableSid = string.Empty;

                var ver = identity.FindFirst("ver")?.Value;

                // the NameIdentifier claim is not stable.
                if (string.Compare(ver, "3", StringComparison.OrdinalIgnoreCase) == 0)
                {
                    // the NameIdentifier claim is not stable.
                    stableSid = identity.FindFirst("stable_sid")?.Value;
                }
                else if (string.Compare(ver, "4", StringComparison.OrdinalIgnoreCase) == 0)
                {
                    // the NameIdentifier claim is stable.
                    stableSid = identity.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                }

                var provider = identity.FindFirst("http://schemas.microsoft.com/identity/claims/identityprovider")?.Value;

                if (string.IsNullOrEmpty(stableSid) || string.IsNullOrEmpty(provider))
                {
                    return null;
                }

                return $"{provider}|{stableSid}";
            }

            return null;
        }


        public static string UniqueUserIdentifier(this HttpRequest request)
        {
            var stableSid = request.ClientPrincipalId();
            var provider = request.ClientPrincipalProvider();

            return $"{provider}|{stableSid}";
        }


        public static string ClientPrincipalName(this HttpRequest request)
        {
            if (request.Headers.TryGetValue(xmsClientPrincipalNameKey, out var stringValue))
            {
                return stringValue;
            }
            return null;
        }


        public static string ClientPrincipalId(this HttpRequest request)
        {
            if (request.Headers.TryGetValue(xmsClientPrincipalIdKey, out var stringValue))
            {
                return stringValue;
            }
            return null;
        }


        public static string ClientPrincipalProvider(this HttpRequest request)
        {
            if (request.Headers.TryGetValue(xmsClientPrincipalProviderKey, out var stringValue))
            {
                return stringValue;
            }
            return null;
        }


        public static Uri UriFromIssuerClaim(this ClaimsIdentity identity)
        {
            return new Uri(identity?.FindFirst(JwtRegisteredClaimNamesIss)?.Value);
        }


        public static void ConfigureClientForUserDetails(this HttpClient client, HttpRequestMessage req)
        {
            var zumoAuthHeader = req.Headers.GetValues(zumoAuthHeaderKey).FirstOrDefault();

            client.DefaultRequestHeaders.Remove(zumoAuthHeaderKey);

            client.DefaultRequestHeaders.Add(zumoAuthHeaderKey, zumoAuthHeader);
        }


        public static ClaimsIdentity GetClaimsIdentity(this IPrincipal currentPricipal)
        {
            if (currentPricipal?.Identity != null
                && currentPricipal.Identity.IsAuthenticated
                && currentPricipal is ClaimsPrincipal principal
                && principal.Identity is ClaimsIdentity identity)
            {
                return identity;
            }

            return null;
        }
    }
}
