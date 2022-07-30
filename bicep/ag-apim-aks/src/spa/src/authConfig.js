/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */

import { LogLevel } from "@azure/msal-browser";

/**
 * Configuration object to be passed to MSAL instance on creation. 
 * For a full list of MSAL.js configuration parameters, visit:
 * https://github.com/AzureAD/microsoft-authentication-library-for-js/blob/dev/lib/msal-browser/docs/configuration.md 
 */
export const msalConfig = {
    auth: {
        clientId: "",
        authority: "https://login.microsoftonline.com/kainiindustries.net",
        redirectUri: "https://api.aksdemo.kainiindustries.net" //"http://localhost:3000" //"https://api.aksdemo.kainiindustries.net"  
    },
    cache: {
        cacheLocation: "sessionStorage", // This configures where your cache will be stored
        storeAuthStateInCookie: false, // Set this to "true" if you are having issues on IE11 or Edge
    },
    system: {
        loggerOptions: {
            loggerCallback: (level, message, containsPii) => {
                if (containsPii) {
                    return;
                }
                switch (level) {
                    case LogLevel.Error:
                        console.error(message);
                        return;
                    case LogLevel.Info:
                        console.info(message);
                        return;
                    case LogLevel.Verbose:
                        console.debug(message);
                        return;
                    case LogLevel.Warning:
                        console.warn(message);
                        return;
                }
            }
        }
    }
};

/**
 * Scopes you add here will be prompted for user consent during sign-in.
 * By default, MSAL.js will add OIDC scopes (openid, profile, email) to any login request.
 * For more information about OIDC scopes, visit: 
 * https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent#openid-connect-scopes
 */
export const loginRequest = {
    scopes: [
        "api://884f182c-de06-4811-a1f5-bba2ae782e66/Order.Write",
        "api://884f182c-de06-4811-a1f5-bba2ae782e66/Order.Read"
    ]
};

export const orderApi = {
    scopes: [
        "api://884f182c-de06-4811-a1f5-bba2ae782e66/Order.Write",
        "api://884f182c-de06-4811-a1f5-bba2ae782e66/Order.Read"
    ],
}

export const productApi = {
    scopes: [
        "api://d08a3928-5afb-4240-ba7a-f823ac0e0a71/Product.Write",
        "api://d08a3928-5afb-4240-ba7a-f823ac0e0a71/Product.Read"
    ],
}

export const apiConfig = {
    orderApiEndpoint: "https://api.aksdemo.kainiindustries.net/api/order/orders",
    productApiEndpoint: "https://api.aksdemo.kainiindustries.net/api/product/products"
}
