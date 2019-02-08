/*
 * The MIT License (MIT)
 *
 * Copyright © 2019 YML. All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the “Software”), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall
 * be included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */
package com.yml.azureimageupload.azure;

import com.microsoft.azure.storage.CloudStorageAccount;
import com.microsoft.azure.storage.blob.CloudBlobClient;

import java.net.URISyntaxException;
import java.security.InvalidKeyException;

public class StorageProvider {
    private static final String STORAGE_CONNECTION_STRING = "SET YOUR VALUE HERE";

    private static StorageProvider storageProvider;

    private CloudBlobClient cloudBlobClient;

    private StorageProvider() {
        try {
            final CloudStorageAccount storageAccount = CloudStorageAccount
                    .parse(STORAGE_CONNECTION_STRING);
            cloudBlobClient = storageAccount.createCloudBlobClient();

        } catch (URISyntaxException | InvalidKeyException e) {
            e.printStackTrace();
        }
    }

    public static synchronized StorageProvider getInstance() {
        if (storageProvider == null) {
            storageProvider = new StorageProvider();
        }
        return storageProvider;
    }

    public CloudBlobClient getCloudBlobClient() {
        return cloudBlobClient;
    }

}