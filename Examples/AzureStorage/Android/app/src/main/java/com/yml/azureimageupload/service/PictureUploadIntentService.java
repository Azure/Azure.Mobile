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

package com.yml.azureimageupload.service;

import android.app.IntentService;
import android.content.Context;
import android.content.Intent;
import android.support.v4.content.LocalBroadcastManager;

import com.microsoft.azure.storage.blob.CloudBlobClient;
import com.microsoft.azure.storage.blob.CloudBlobContainer;
import com.microsoft.azure.storage.blob.CloudBlockBlob;
import com.orhanobut.logger.Logger;
import com.yml.azureimageupload.azure.StorageProvider;
import com.yml.azureimageupload.utils.Constant;

import java.io.File;
import java.io.FileInputStream;


public class PictureUploadIntentService extends IntentService {

    private static final String ACTION_UPLOAD = "com.yml.azureimageupload.service.action.UPLOAD_ACTION";
    private static final String EXTRA_FILE_NAME = "com.yml.azureimageupload.service.extra.FILE_NAME";

    public PictureUploadIntentService() {
        super("PictureUploadIntentService");
    }


    public static void startActionUploadImage(Context context, String fileName) {
        Intent intent = new Intent(context, PictureUploadIntentService.class);
        intent.setAction(ACTION_UPLOAD);
        intent.putExtra(EXTRA_FILE_NAME, fileName);
        context.startService(intent);
    }


    @Override
    protected void onHandleIntent(Intent intent) {
        if (intent != null) {
            final String action = intent.getAction();
            if (ACTION_UPLOAD.equals(action)) {

                String fileName = intent.getStringExtra(EXTRA_FILE_NAME);
                File file = new File(fileName);
                handleActionUploadImage(file);

            }
        }
    }

    private void handleActionUploadImage(final File file) {
        Intent intent = new Intent(Constant.UPLOAD_ACTION); //put the same message as in the filter you used in the activity when registering the receiver
        intent.putExtra(Constant.UPLOAD_STATUS, "started");
        LocalBroadcastManager.getInstance(PictureUploadIntentService.this).sendBroadcast(intent);
        Logger.e("file came to upload :" + file.getAbsolutePath());
        Thread thread = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    final CloudBlobClient cloudBlobClient = StorageProvider.getInstance().getCloudBlobClient();
                    CloudBlobContainer mybucket = cloudBlobClient.getContainerReference(Constant.BUCKET_NAME);

                    CloudBlockBlob mybucketBlockBlobReference = mybucket.getBlockBlobReference(file.getName());
                    mybucketBlockBlobReference.upload(new FileInputStream(file), file.length());

                    Logger.i("Upload completed");
                    Intent intent = new Intent(Constant.UPLOAD_ACTION); //put the same message as in the filter you used in the activity when registering the receiver
                    intent.putExtra(Constant.UPLOAD_STATUS, "complete");
                    LocalBroadcastManager.getInstance(PictureUploadIntentService.this).sendBroadcast(intent);
                    Logger.e("Deleted? file: " + file.delete());

                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
        thread.start();
    }
}
