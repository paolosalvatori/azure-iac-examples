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
        clientId: "91064216-326e-4375-aa0f-e241562b5454",
        authority: "https://login.microsoftonline.com/kainiindustries.net",
        redirectUri: "https://spa.aksdemo.kainiindustries.net" //"http://localhost:3000"   
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
    scopes: ["api://13e29a9f-91d4-4761-acfa-acb2f3976bb1/Read"]
};

export const apiConfig = {
    orderApiEndpoint:"https://api.aksdemo.kainiindustries.net/order-api/orders",
    productApiEndpoint:"https://api.aksdemo.kainiindustries.net/product-api/products",
    orderApiReadScope: ["api://13e29a9f-91d4-4761-acfa-acb2f3976bb1/Read"],
    orderApiWriteScope: ["api://13e29a9f-91d4-4761-acfa-acb2f3976bb1/Write"],
    productApiReadScope: ["api://3c0926b2-5449-46dd-aa8a-704367230582/Read"],
    productApiWriteScope: ["api://3c0926b2-5449-46dd-aa8a-704367230582/Write"]
}
