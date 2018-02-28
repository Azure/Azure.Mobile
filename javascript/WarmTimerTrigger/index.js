/**
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License.
 */

module.exports = function (context, warmTimer) {
    
    var timeStamp = new Date().toISOString();

    if (warmTimer.isPastDue) {
        context.log('JavaScript is running late!');
    }

    context.log('Warm timer trigger function ran!', timeStamp);

    context.done();
};