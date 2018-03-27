_Looking for the client SDKs? You can find them in the [Azure.iOS][azure-ios] and [Azure.Android][azure-android] repos._


# Azure.Mobile [![Build Status](https://travis-ci.org/Azure/Azure.Mobile.svg?branch=master)](https://travis-ci.org/Azure/Azure.Mobile)

**[Azure.Mobile](https://aka.ms/mobile) is a framework for rapidly creating iOS and android apps with modern, highly-scalable backends on Azure.**

Azure.Mobile has two simple objectives:

1. Enable developers to create, configure, deploy all necessary backend services fast — ideally under 10 minutes with only a few clicks
2. Provide native iOS and android SDKs with delightful APIs to interact with the services


## What's included?

It includes one-click deployment templates and native client SDKs for the following:

- [Database (document)][cosmos]
- [Blob/File/Queue Storage][storage]
- [Authentication][app-service]
- [Push Notifications][notification-hub]
- [Serverless Functions][functions]
- [Client/Server Analytics][app-insights]
- [Secure Key Storage][key-vault]

![architecture-diagram](assets/AzureMobile1400_1000.png?raw=true "architecture diagram")


# Getting Started

## 1. Azure Account

To use Azure.Mobile, you'll need an Azure account.  If you already have one, make sure you’re [logged in](https://portal.azure.com) and move to the next step.

If you don't have an Azure account, [sign up for a Azure free account][azure-free] before moving to the next step.


## 2. Deploy Azure Services

Deploying the Azure resources is as simple as clicking the link below then filling out the form per the instructions in the next step:

[![Deploy to Azure][azure-deploy-button]][azure-deploy]


## 3. Fill in Template Form

There's a few fields to fill out in order to create and deploy the Azure resources defined in the template.

Below is a brief explanation/guidance for filling in each field, please [file an issue](issues/new?labels=docs) if you have questions or require additional help.


- **`Subscription:`** Choose which Azure subscription you want to use to deploy the backend.  If you only have one choice, or you don't see this option at all, don't sweat it.

- **`Resource group:`** Unless you have an existing Resource group that you know you want to use, select __Create new__ and provide a name for the new group.  _(a resource group is essentially a parent folder to deploy the new database, app service, etc. to)_

- **`Location:`** Select the region to deploy the new resources. You want to choose a region that best describes your location (or your users location).

- **`Web Site Name:`** Provide a name for your app.  This can be the same name as your Resource group, and will be used as the subdomain for your service endpoint.  For example, if you used `superawesome`, your serverless app would live at `superawesome.azurewebsites.net`.

- **`Function Language:`** The template will deploy a serverless app with a few boilerplate functions.  This is the programming language those functions will be written in.  Choose the language you're most comfortable with.

- **Agree & Purchase:** Read and agree to the _TERMS AND CONDITIONS_, then click _Purchase_.


## 4. Configure iOS/Android app

Once you deploy the Azure services, all that's left to do is your app.  You'll find detailed instructions for setting up and using the iOS & Android SDKs in their respective repos:

- [iOS SDK][azure-ios]
- [Android SDK][azure-android]



# How is this different than Azure Mobile Apps?

Azure Mobile Apps _(formally Azure App Services)_ is...



# What is the price/cost?

Most of these services have a generous free tier. [Sign up for a Azure free account][azure-free] to get $200 credit.



# About
This project is in active development and will change.

## Contributing
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).  
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Reporting Security Issues
Security issues and bugs should be reported privately, via email, to the Microsoft Security Response Center (MSRC) at [secure@microsoft.com](mailto:secure@microsoft.com). You should receive a response within 24 hours. If for some reason you do not, please follow up via email to ensure we received your original message. Further information, including the [MSRC PGP](https://technet.microsoft.com/en-us/security/dn606155) key, can be found in the [Security TechCenter](https://technet.microsoft.com/en-us/security/default).

## License
Copyright (c) Microsoft Corporation. All rights reserved.  
Licensed under the MIT License.  See [LICENSE](License) for details.




[azure-ios]:https://aka.ms/azureios
[azure-android]:https://aka.ms/azureandroid

[cosmos]:https://azure.microsoft.com/en-us/services/cosmos-db
[key-vault]:https://azure.microsoft.com/en-us/services/key-vault
[app-service]:https://azure.microsoft.com/en-us/services/app-service
[functions]:https://azure.microsoft.com/en-us/services/functions
[storage]:https://azure.microsoft.com/en-us/services/storage
[notification-hub]:https://azure.microsoft.com/en-us/services/notification-hubs
[app-insights]:https://azure.microsoft.com/en-us/services/application-insights

[azure-deploy]:https://aka.ms/mobile-deploy
[azure-deploy-button]:https://azuredeploy.net/deploybutton.svg

[azure-visualize]:http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure.Mobile%2Fmaster%2Fazuredeploy.json
[azure-visualize-button]:http://armviz.io/visualizebutton.png


[azure-free]:https://azure.microsoft.com/en-us/free/