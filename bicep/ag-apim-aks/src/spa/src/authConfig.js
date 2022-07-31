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
        clientId: "c2d86682-e005-4458-bf4a-8fb1488e8f18",
        authority: "https://login.microsoftonline.com/kainiindustries.net",
        redirectUri: "https://api.aksdemo.kainiindustries.net"
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
        "api://66da3166-c909-4932-9c11-a062d3125263/Order.Write",
        "api://66da3166-c909-4932-9c11-a062d3125263/Order.Read"
    ]
};

export const orderApi = {
    scopes: [
        "api://66da3166-c909-4932-9c11-a062d3125263/Order.Write",
        "api://66da3166-c909-4932-9c11-a062d3125263/Order.Read"
    ],
}

export const productApi = {
    scopes: [
        "api://81afb75d-8e29-494a-8693-2fb83a0b8d24/Product.Write",
        "api://81afb75d-8e29-494a-8693-2fb83a0b8d24/Product.Read"
    ],
}

export const apiConfig = {
    orderApiEndpoint: "https://api.aksdemo.kainiindustries.net/api/order/orders",
    productApiEndpoint: "https://api.aksdemo.kainiindustries.net/api/product/products"
}
