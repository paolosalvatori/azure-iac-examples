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
        clientId: "7c718b9b-f834-4e0a-afe7-0f8efe64c49d", //"91064216-326e-4375-aa0f-e241562b5454",
        authority: "https://login.microsoftonline.com/kainiindustries.net",
        redirectUri: "http://localhost:3000" //"https://api.aksdemo.kainiindustries.net"
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
    scopes: [`${msalConfig.auth.clientId}/.default`]
};

export const orderApi = {
    scopes: [
        "api://53699ced-3870-4078-b44e-b2fab9c65ce3/Order.Read",
        "api://53699ced-3870-4078-b44e-b2fab9c65ce3/Order.Write"
    ],
}

export const productApi = {
    scopes: [
        "api://5c160889-49cb-4448-a6cf-56050a0ad4aa/Product.Read",
        "api://5c160889-49cb-4448-a6cf-56050a0ad4aa/Product.Write"
    ],
}

export const apiConfig = {
    orderApiEndpoint: "https://api.aksdemo.kainiindustries.net/api/order/orders",
    productApiEndpoint: "https://api.aksdemo.kainiindustries.net/api/product/products"
}
